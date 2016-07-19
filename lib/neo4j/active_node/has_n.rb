module Neo4j::ActiveNode
  module HasN
    extend ActiveSupport::Concern

    class NonPersistedNodeError < Neo4j::Error; end

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
        if @cached_result
          result_nodes.inspect
        else
          "#<AssociationProxy @query_proxy=#{@query_proxy.inspect}>"
        end
      end

      extend Forwardable
      %w(include? empty? count find first last ==).each do |delegated_method|
        def_delegator :@enumerable, delegated_method
      end

      include Enumerable

      def each(&block)
        result_nodes.each(&block)
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

        result_objects.map do |object|
          object.is_a?(Neo4j::ActiveNode) ? object : @query_proxy.model.find(object)
        end
      end

      def result_objects
        @deferred_objects + result_without_deferred
      end

      def result_ids
        result.map do |object|
          object.is_a?(Neo4j::ActiveNode) ? object.id : object
        end
      end

      def cache_result(result)
        @cached_result = result
        @enumerable = (@cached_result || @query_proxy)
      end

      def add_to_cache(object)
        @cached_result ||= []
        @cached_result << object
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
        @cached_result = nil

        @query_proxy.public_send(:replace_with, *args)
      end

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

        cache_query_proxy_result if !cached? && !target.is_a?(Neo4j::ActiveNode::Query::QueryProxy)
        clear_cache_result if target.is_a?(Neo4j::ActiveNode::Query::QueryProxy)

        target.public_send(method_name, *args, &block)
      end

      def serializable_hash(options = {})
        to_a.map { |record| record.serializable_hash(options) }
      end

      private

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
    # { :association_name => AssociationProxy}
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

    private

    def fresh_association_proxy(name, options = {}, result_cache_proc = nil)
      AssociationProxy.new(association_query_proxy(name, options), deferred_nodes_for_association(name), result_cache_proc)
    end

    def previous_proxy_results_by_previous_id(result_cache, association_name)
      query_proxy = self.class.as(:previous).where(neo_id: result_cache.map(&:neo_id))
      query_proxy = self.class.send(:association_query_proxy, association_name, previous_query_proxy: query_proxy, node: :next, optional: true)

      Hash[*query_proxy.pluck('ID(previous)', 'collect(next)').flatten(1)].each do |_, records|
        records.each do |record|
          record.instance_variable_set('@source_proxy_result_cache', records)
        end
      end
    end

    module ClassMethods
      # rubocop:disable Style/PredicateName

      # :nocov:
      def has_association?(name)
        ActiveSupport::Deprecation.warn 'has_association? is deprecated and may be removed from future releases, use association? instead.', caller

        association?(name)
      end
      # :nocov:

      # rubocop:enable Style/PredicateName

      def association?(name)
        !!associations[name.to_sym]
      end

      def associations
        @associations ||= {}
      end

      def associations_keys
        @associations_keys ||= associations.keys
      end

      # make sure the inherited classes inherit the <tt>_decl_rels</tt> hash
      def inherited(klass)
        klass.instance_variable_set(:@associations, associations.clone)
        @associations_keys = klass.associations_keys.clone
        super
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
      #       Symbol/String (or an ``Array`` of same) with the name of the `ActiveNode` class,
      #       `false` to specify any model, or nil to specify that it should be guessed.
      #
      #     *rel_class*: The ``ActiveRel`` class to use for this association.  Can be either a
      #       model object ``include`` ing ``ActiveRel`` or a Symbol/String (or an ``Array`` of same).
      #       **A Symbol or String is recommended** to avoid load-time issues
      #
      #     *dependent*: Enables deletion cascading.
      #       **Available values:** ``:delete``, ``:delete_orphans``, ``:destroy``, ``:destroy_orphans``
      #       (note that the ``:destroy_orphans`` option is known to be "very metal".  Caution advised)
      #
      def has_many(direction, name, options = {}) # rubocop:disable Style/PredicateName
        name = name.to_sym
        build_association(:has_many, direction, name, options)

        define_has_many_methods(name)
      end

      # For defining an "has one" association on a model.  This defines a set of methods on
      # your model instances.  For instance, if you define the association on a Person model:
      #
      # has_one :out, :vehicle, type: :has_vehicle
      #
      # This would define the methods: ``#vehicle``, ``#vehicle=``, and ``.vehicle``.
      #
      # See :ref:`#has_many <Neo4j/ActiveNode/HasN/ClassMethods#has_many>` for anything
      # not specified here
      #
      def has_one(direction, name, options = {}) # rubocop:disable Style/PredicateName
        name = name.to_sym
        build_association(:has_one, direction, name, options)

        define_has_one_methods(name)
      end

      private

      def define_has_many_methods(name)
        define_method(name) do |node = nil, rel = nil, options = {}|
          # return [].freeze unless self._persisted_obj

          options, node = node, nil if node.is_a?(Hash)

          association_proxy(name, {node: node, rel: rel, source_object: self, labels: options[:labels]}.merge!(options))
        end

        define_has_many_setter(name)

        define_has_many_id_methods(name)

        define_class_method(name) do |node = nil, rel = nil, options = {}|
          options, node = node, nil if node.is_a?(Hash)

          association_proxy(name, {node: node, rel: rel, labels: options[:labels]}.merge!(options))
        end
      end

      def define_has_many_setter(name)
        define_method("#{name}=") do |other_nodes|
          association_proxy_cache.clear

          clear_deferred_nodes_for_association(name)

          Neo4j::Transaction.run { association_proxy(name).replace_with(other_nodes) }
        end
      end

      def define_has_many_id_methods(name)
        define_method_unless_defined("#{name.to_s.singularize}_ids") do
          association_proxy(name).result_ids
        end

        define_method_unless_defined("#{name.to_s.singularize}_ids=") do |ids|
          clear_deferred_nodes_for_association(name)
          association_proxy(name).replace_with(ids)
        end

        define_method_unless_defined("#{name.to_s.singularize}_neo_ids") do
          association_proxy(name).pluck(:neo_id)
        end
      end

      def define_method_unless_defined(method_name, &block)
        define_method(method_name, block) unless method_defined?(method_name)
      end

      def define_has_one_methods(name)
        define_has_one_getter(name)

        define_has_one_setter(name)

        define_has_one_id_methods(name)

        define_class_method(name) do |node = nil, rel = nil, options = {}|
          options, node = node, nil if node.is_a?(Hash)

          association_proxy(name, {node: node, rel: rel, labels: options[:labels]}.merge!(options))
        end
      end

      def define_has_one_id_methods(name)
        define_method_unless_defined("#{name}_id") do
          association_proxy(name).result_ids.first
        end

        define_method_unless_defined("#{name}_id=") do |id|
          association_proxy(name).replace_with(id)
        end

        define_method_unless_defined("#{name}_neo_id") do
          association_proxy(name).pluck(:neo_id).first
        end
      end

      def define_has_one_getter(name)
        define_method(name) do |node = nil, rel = nil, options = {}|
          options, node = node, nil if node.is_a?(Hash)

          # Return all results if a variable-length relationship length was given
          association_proxy = association_proxy(name, {node: node, rel: rel}.merge!(options))
          if options[:rel_length] && !options[:rel_length].is_a?(Fixnum)
            association_proxy
          else
            target_class = self.class.send(:association_target_class, name)
            o = association_proxy.result.first
            if target_class
              target_class.send(:nodeify, o)
            else
              o
            end
          end
        end
      end

      def define_has_one_setter(name)
        define_method("#{name}=") do |other_node|
          if persisted?
            other_node.save if other_node.respond_to?(:persisted?) && !other_node.persisted?
            association_proxy_cache.clear # TODO: Should probably just clear for this association...
            Neo4j::Transaction.run { association_proxy(name).replace_with(other_node) }
            # handle_non_persisted_node(other_node)
          else
            defer_create(name, other_node, clear: true)
            other_node
          end
        end
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
        Neo4j::ActiveNode::Query::QueryProxy.new(association_target_class(name),
                                                 associations[name],
                                                 {session: neo4j_session,
                                                  query_proxy: query_proxy,
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
        Neo4j::ActiveNode::Query::QueryProxy.new("::#{self.name}".constantize, nil,
                                                 session: neo4j_session, query_proxy: nil, context: "#{self.name}")
      end

      def build_association(macro, direction, name, options)
        options[:model_class] = options[:model_class].name if options[:model_class] == self
        Neo4j::ActiveNode::HasN::Association.new(macro, direction, name, options).tap do |association|
          @associations ||= {}
          @associations[name] = association
          create_reflection(macro, name, association, self)
        end

        associations_keys << name

      # Re-raise any exception with added class name and association name to
      # make sure error message is helpful
      rescue StandardError => e
        raise e.class, "#{e.message} (#{self.class}##{name})"
      end
    end
  end
end
