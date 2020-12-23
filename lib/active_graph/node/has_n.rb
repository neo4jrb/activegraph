module ActiveGraph::Node
  module HasN
    extend ActiveSupport::Concern

    class NonPersistedNodeError < ActiveGraph::Error; end
    class HasOneConstraintError < ActiveGraph::Error; end
    # Return this object from associations
    # It uses a QueryProxy to get results
    # But also caches results and can have results cached on it
    class AssociationProxy
      def initialize(query_proxy, deferred_objects = [], result_cache_proc = nil)
        @query_proxy = query_proxy
        @deferred_objects = deferred_objects

        @result_cache_proc = result_cache_proc

        # Represents the thing which can be enumerated
        # default to @query_proxy, but will be set to
        # @cached_result if that is set
        @enumerable = @query_proxy
      end

      # States:
      # Default
      def inspect
        formatted_nodes = ::ActiveGraph::Node::NodeListFormatter.new(result_nodes)
        "#<AssociationProxy #{@query_proxy.context} #{formatted_nodes.inspect}>"
      end

      extend Forwardable
      %w(include? find first last ==).each do |delegated_method|
        def_delegator :@enumerable, delegated_method
      end

      include Enumerable

      def each(&block)
        result_nodes.each(&block)
      end

      def each_rel(&block)
        rels.each(&block)
      end

      # .count always hits the database
      def_delegator :@query_proxy, :count

      def length
        @deferred_objects.length + @enumerable.length
      end

      def size
        @deferred_objects.size + @enumerable.size
      end

      def empty?(*args)
        @deferred_objects.empty? && @enumerable.empty?(*args)
      end

      def ==(other)
        self.to_a == other.to_a
      end

      def +(other)
        self.to_a + other
      end

      def result
        (@deferred_objects || []) + result_without_deferred
      end

      def result_without_deferred
        cache_query_proxy_result if !@cached_result

        @cached_result
      end

      def result_nodes
        return result_objects if !@query_proxy.model

        map_results_as_nodes(result_objects)
      end

      def result_objects
        @deferred_objects + result_without_deferred
      end

      def result_ids
        result.map do |object|
          object.is_a?(ActiveGraph::Node) ? object.id : object
        end
      end

      def cache_result(result)
        @cached_result = result
        @enumerable = (@cached_result || @query_proxy)
      end

      def init_cache
        @cached_rels ||= []
        @cached_result ||= []
      end

      def add_to_cache(object, rel = nil)
        (@cached_rels ||= []) << rel if rel
        (@cached_result ||= []).tap { |results| results << object unless results.include?(object) }
      end

      def rels
        @cached_rels || super
      end

      def cache_query_proxy_result
        (result_cache_proc_cache || @query_proxy).to_a.tap { |result| cache_result(result) }
      end

      def result_cache_proc_cache
        @result_cache_proc_cache ||= @result_cache_proc.call if @result_cache_proc
      end

      def clear_cache_result
        cache_result(nil)
      end

      def cached?
        !!@cached_result
      end

      def replace_with(*args)
        nodes = @query_proxy.replace_with(*args).to_a
        if @query_proxy.start_object.try(:new_record?)
          @cached_result = nil
        else
          cache_result(nodes)
        end
      end

      alias to_ary to_a

      QUERY_PROXY_METHODS = [:<<, :delete, :create, :pluck, :where, :where_not, :rel_where, :rel_order, :order, :skip, :limit]

      QUERY_PROXY_METHODS.each do |method|
        define_method(method) do |*args, &block|
          @query_proxy.public_send(method, *args, &block)
        end
      end

      CACHED_RESULT_METHODS = []

      def method_missing(method_name, *args, &block)
        target = target_for_missing_method(method_name)
        super if target.nil?

        cache_query_proxy_result if !cached? && !target.is_a?(ActiveGraph::Node::Query::QueryProxy)
        clear_cache_result if target.is_a?(ActiveGraph::Node::Query::QueryProxy)

        target.public_send(method_name, *args, &block)
      end

      def serializable_hash(options = {})
        to_a.map { |record| record.serializable_hash(options) }
      end

      private

      def map_results_as_nodes(result)
        result.map do |object|
          object.is_a?(ActiveGraph::Node) ? object : @query_proxy.model.find(object)
        end
      end

      def target_for_missing_method(method_name)
        case method_name
        when *CACHED_RESULT_METHODS
          @cached_result
        else
          if @cached_result && @cached_result.respond_to?(method_name)
            @cached_result
          elsif @query_proxy.respond_to?(method_name)
            @query_proxy
          end
        end
      end
    end

    # Returns the current AssociationProxy cache for the association cache. It is in the format
    # { hash => AssociationProxy}
    # where hash is the result of calling #association_proxy_hash with the association name
    # This is so that we
    # * don't need to re-build the QueryProxy objects
    # * also because the QueryProxy object caches it's results
    # * so we don't need to query again
    # * so that we can cache results from association calls or eager loading
    def association_proxy_cache
      @association_proxy_cache ||= {}
    end

    def association_proxy_cache_fetch(key)
      association_proxy_cache.fetch(key) do
        value = yield
        association_proxy_cache[key] = value
      end
    end

    def association_query_proxy(name, options = {})
      self.class.send(:association_query_proxy, name, {start_object: self}.merge!(options))
    end

    def association_proxy_hash(name, options = {})
      [name.to_sym, options.values_at(:node, :rel, :labels, :rel_length)].hash
    end

    def association_proxy(name, options = {})
      name = name.to_sym
      hash = association_proxy_hash(name, options)
      association_proxy_cache_fetch(hash) do
        if result_cache = self.instance_variable_get('@source_proxy_result_cache')
          cache = nil
          result_cache.inject(nil) do |proxy_to_return, object|
            proxy = fresh_association_proxy(name, options.merge(start_object: object),
                                            proc { (cache ||= previous_proxy_results_by_previous_id(result_cache, name))[object.neo_id] })

            object.association_proxy_cache[hash] = proxy

            (self == object ? proxy : proxy_to_return)
          end
        else
          fresh_association_proxy(name, options)
        end
      end
    end

    def delete_reverse_has_one_core_rel(association)
      reverse_assoc = reverse_association(association)
      delete_has_one_rel!(reverse_assoc) if reverse_assoc && reverse_assoc.type == :has_one
    end

    def reverse_association(association)
      reverse_assoc = self.class.associations.find do |_key, assoc|
        association.inverse_of?(assoc) || assoc.inverse_of?(association)
      end
      reverse_assoc && reverse_assoc.last
    end

    def delete_reverse_has_one_relationship(relationship, direction, other_node)
      rel = relationship_corresponding_rel(relationship, direction, other_node.class)
      delete_has_one_rel!(rel.last) if rel && rel.last.type == :has_one
    end

    def delete_has_one_rel!(rel)
      send("#{rel.name}", :n, :r, chainable: true).query.delete(:r).exec
      association_proxy_cache.clear
    end

    def relationship_corresponding_rel(relationship, direction, target_class)
      self.class.associations.find do |_key, assoc|
        assoc.relationship_class_name == relationship.class.name ||
          (assoc.relationship_type == relationship.type.to_sym && assoc.target_class == target_class && assoc.direction == direction)
      end
    end

    private

    def fresh_association_proxy(name, options = {}, result_cache_proc = nil)
      AssociationProxy.new(association_query_proxy(name, options), deferred_nodes_for_association(name), result_cache_proc)
    end

    def previous_proxy_results_by_previous_id(result_cache, association_name)
      query_proxy = self.class.as(:previous).where(neo_id: result_cache.map(&:neo_id))
      query_proxy = self.class.send(:association_query_proxy, association_name, previous_query_proxy: query_proxy, node: :next, optional: true)

      Hash[*query_proxy.pluck('ID(previous)', 'collect(next)').flatten(1)].each_value do |records|
        records.each do |record|
          record.instance_variable_set('@source_proxy_result_cache', records)
        end
      end
    end

    # rubocop:disable Metrics/ModuleLength
    module ClassMethods
      # rubocop:disable Naming/PredicateName

      # :nocov:
      def has_association?(name)
        ActiveSupport::Deprecation.warn 'has_association? is deprecated and may be removed from future releases, use association? instead.', caller

        association?(name)
      end
      # :nocov:

      # rubocop:enable Naming/PredicateName

      def association?(name)
        !!associations[name.to_sym]
      end

      def parent_associations
        superclass == Object ? {} : superclass.associations
      end

      def associations
        (@associations ||= parent_associations.dup)
      end

      def associations_keys
        @associations_keys ||= associations.keys
      end

      # For defining an "has many" association on a model.  This defines a set of methods on
      # your model instances.  For instance, if you define the association on a Person model:
      #
      #
      # .. code-block:: ruby
      #
      #   has_many :out, :vehicles, type: :has_vehicle
      #
      # This would define the following methods:
      #
      # **#vehicles**
      #   Returns a QueryProxy object.  This is an Enumerable object and thus can be iterated
      #   over.  It also has the ability to accept class-level methods from the Vehicle model
      #   (including calls to association methods)
      #
      # **#vehicles=**
      #   Takes an array of Vehicle objects and replaces all current ``:HAS_VEHICLE`` relationships
      #   with new relationships refering to the specified objects
      #
      # **.vehicles**
      #   Returns a QueryProxy object.  This would represent all ``Vehicle`` objects associated with
      #   either all ``Person`` nodes (if ``Person.vehicles`` is called), or all ``Vehicle`` objects
      #   associated with the ``Person`` nodes thus far represented in the QueryProxy chain.
      #   For example:
      #
      #   .. code-block:: ruby
      #
      #     company.people.where(age: 40).vehicles
      #
      # Arguments:
      #   **direction:**
      #     **Available values:** ``:in``, ``:out``, or ``:both``.
      #
      #     Refers to the relative to the model on which the association is being defined.
      #
      #     Example:
      #
      #     .. code-block:: ruby
      #
      #       Person.has_many :out, :posts, type: :wrote
      #
      #     means that a `WROTE` relationship goes from a `Person` node to a `Post` node
      #
      #   **name:**
      #     The name of the association.  The affects the methods which are created (see above).
      #     The name is also used to form default assumptions about the model which is being referred to
      #
      #     Example:
      #
      #     .. code-block:: ruby
      #
      #       Person.has_many :out, :posts, type: :wrote
      #
      #     will assume a `model_class` option of ``'Post'`` unless otherwise specified
      #
      #   **options:** A ``Hash`` of options.  Allowed keys are:
      #     *type*: The Neo4j relationship type.  This option is required unless either the
      #       `origin` or `rel_class` options are specified
      #
      #     *origin*: The name of the association from another model which the `type` and `model_class`
      #       can be gathered.
      #
      #       Example:
      #
      #       .. code-block:: ruby
      #
      #         # `model_class` of `Post` is assumed here
      #         Person.has_many :out, :posts, origin: :author
      #
      #         Post.has_one :in, :author, type: :has_author, model_class: :Person
      #
      #     *model_class*: The model class to which the association is referring.  Can be a
      #       Symbol/String (or an ``Array`` of same) with the name of the `Node` class,
      #       `false` to specify any model, or nil to specify that it should be guessed.
      #
      #     *rel_class*: The ``Relationship`` class to use for this association.  Can be either a
      #       model object ``include`` ing ``Relationship`` or a Symbol/String (or an ``Array`` of same).
      #       **A Symbol or String is recommended** to avoid load-time issues
      #
      #     *dependent*: Enables deletion cascading.
      #       **Available values:** ``:delete``, ``:delete_orphans``, ``:destroy``, ``:destroy_orphans``
      #       (note that the ``:destroy_orphans`` option is known to be "very metal".  Caution advised)
      #
      def has_many(direction, name, options = {}) # rubocop:disable Naming/PredicateName
        name = name.to_sym
        build_association(:has_many, direction, name, options)

        define_has_many_methods(name, options)
      end

      # For defining an "has one" association on a model.  This defines a set of methods on
      # your model instances.  For instance, if you define the association on a Person model:
      #
      # has_one :out, :vehicle, type: :has_vehicle
      #
      # This would define the methods: ``#vehicle``, ``#vehicle=``, and ``.vehicle``.
      #
      # See :ref:`#has_many <ActiveGraph/Node/HasN/ClassMethods#has_many>` for anything
      # not specified here
      #
      def has_one(direction, name, options = {}) # rubocop:disable Naming/PredicateName
        name = name.to_sym
        build_association(:has_one, direction, name, options)

        define_has_one_methods(name, options)
      end

      private

      def define_has_many_methods(name, association_options)
        default_options = association_options.slice(:labels)

        define_method(name) do |node = nil, rel = nil, options = {}|
          # return [].freeze unless self._persisted_obj

          options, node = node, nil if node.is_a?(Hash)

          options = default_options.merge(options)

          association_proxy(name, {node: node, rel: rel, source_object: self, labels: options[:labels]}.merge!(options))
        end

        define_has_many_setter(name)

        define_has_many_id_methods(name)

        define_class_method(name) do |node = nil, rel = nil, options = {}|
          options, node = node, nil if node.is_a?(Hash)

          options = default_options.merge(options)

          association_proxy(name, {node: node, rel: rel, labels: options[:labels]}.merge!(options))
        end
      end

      def define_has_many_setter(name)
        define_setter(name, "#{name}=")
      end

      def define_has_many_id_methods(name)
        define_method_unless_defined("#{name.to_s.singularize}_ids") do
          association_proxy(name).result_ids
        end

        define_setter(name, "#{name.to_s.singularize}_ids=")

        define_method_unless_defined("#{name.to_s.singularize}_neo_ids") do
          association_proxy(name).pluck(:neo_id)
        end
      end

      def define_setter(name, setter_name)
        define_method_unless_defined(setter_name) do |others|
          # todo: how would we handle the case where the association proxy hash
          # had a non-empty options hash passed to it when constructed?
          key = association_proxy_hash(name, {})
          association_proxy_cache.delete(key)

          clear_deferred_nodes_for_association(name)
          others = Array(others).reject(&:blank?)
          if persisted?
            ActiveGraph::Base.transaction { association_proxy(name).replace_with(others) }
          else
            defer_create(name, others, clear: true)
          end
        end
      end

      def define_method_unless_defined(method_name, &block)
        define_method(method_name, block) unless method_defined?(method_name)
      end

      def define_has_one_methods(name, association_options)
        default_options = association_options.slice(:labels)

        define_has_one_getter(name, default_options)

        define_has_one_setter(name)

        define_has_one_id_methods(name)

        define_class_method(name) do |node = nil, rel = nil, options = {}|
          options, node = node, nil if node.is_a?(Hash)

          options = default_options.merge(options)

          association_proxy(name, {node: node, rel: rel, labels: options[:labels]}.merge!(options))
        end
      end

      def define_has_one_id_methods(name)
        define_method_unless_defined("#{name}_id") do
          association_proxy(name).result_ids.first
        end

        define_setter(name, "#{name}_id=")

        define_method_unless_defined("#{name}_neo_id") do
          association_proxy(name).pluck(:neo_id).first
        end
      end

      def define_has_one_getter(name, default_options)
        define_method(name) do |node = nil, rel = nil, options = {}|
          options, node = node, nil if node.is_a?(Hash)

          options = default_options.merge(options)

          association_proxy = association_proxy(name, {node: node, rel: rel}.merge!(options))

          # Return all results if options[:chainable] == true or a variable-length relationship length was given
          if options[:chainable] || (options[:rel_length] && !options[:rel_length].is_a?(Integer))
            association_proxy
          else
            o = association_proxy.result.first
            self.class.send(:association_target_class, name).try(:nodeify, o) || o
          end
        end
      end

      def define_has_one_setter(name)
        define_setter(name, "#{name}=")
      end

      def define_class_method(*args, &block)
        klass = class << self; self; end
        klass.instance_eval do
          define_method(*args, &block)
        end
      end

      def association_query_proxy(name, options = {})
        previous_query_proxy = options[:previous_query_proxy] || current_scope
        query_proxy = previous_query_proxy || default_association_query_proxy
        ActiveGraph::Node::Query::QueryProxy.new(association_target_class(name),
                                                 associations[name],
                                                 {query_proxy: query_proxy,
                                                  context: "#{query_proxy.context || self.name}##{name}",
                                                  optional: query_proxy.optional?,
                                                  association_labels: options[:labels],
                                                  source_object: query_proxy.source_object}.merge!(options)).tap do |query_proxy_result|
                                                    target_classes = association_target_classes(name)
                                                    return query_proxy_result.as_models(target_classes) if target_classes
                                                  end
      end

      def association_proxy(name, options = {})
        AssociationProxy.new(association_query_proxy(name, options))
      end

      def association_target_class(name)
        target_classes_or_nil = associations[name].target_classes_or_nil

        return if !target_classes_or_nil.is_a?(Array) || target_classes_or_nil.size != 1

        target_classes_or_nil[0]
      end

      def association_target_classes(name)
        target_classes_or_nil = associations[name].target_classes_or_nil

        return if !target_classes_or_nil.is_a?(Array) || target_classes_or_nil.size <= 1

        target_classes_or_nil
      end

      def default_association_query_proxy
        ActiveGraph::Node::Query::QueryProxy.new("::#{self.name}".constantize, nil,
                                                 query_proxy: nil, context: self.name.to_s)
      end

      def build_association(macro, direction, name, options)
        options[:model_class] = options[:model_class].name if options[:model_class] == self
        ActiveGraph::Node::HasN::Association.new(macro, direction, name, options).tap do |association|
          add_association(name, association)
          create_reflection(macro, name, association, self)
        end

        @associations_keys = nil

      # Re-raise any exception with added class name and association name to
      # make sure error message is helpful
      rescue StandardError => e
        raise e.class, "#{e.message} (#{self.class}##{name})"
      end

      def add_association(name, association_object)
        fail "Association `#{name}` defined for a second time. "\
             'Associations can only be defined once' if duplicate_association?(name)
        associations[name] = association_object
      end

      def duplicate_association?(name)
        associations.key?(name) && parent_associations[name] != associations[name]
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
