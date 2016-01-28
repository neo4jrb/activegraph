module Neo4j::ActiveNode
  # This module makes it possible to use other IDs than the build it neo4j id (neo_id)
  #
  # @example using generated UUIDs
  #   class Person
  #     include Neo4j::ActiveNode
  #     # creates a 'secret' neo4j property my_uuid which will be used as primary key
  #     id_property :my_uuid, auto: :uuid
  #   end
  #
  # @example using user defined ids
  #   class Person
  #     include Neo4j::ActiveNode
  #     property :title
  #     validates :title, :presence => true
  #     id_property :title_id, on: :title_to_url
  #
  #     def title_to_url
  #       self.title.urlize # uses https://github.com/cheef/string-urlize gem
  #     end
  #   end
  #
  # @example using already exsting ids that you don't want a constraint added to
  #   class Person
  #     include Neo4j::ActiveNode
  #     property :title
  #     validates :title, :presence => true
  #     id_property :id, on: :id_builder, constraint: false
  #
  #     def id_builder
  #       # only need to fill this out if you're gonna write to the db
  #     end
  #   end
  #
  module IdProperty
    extend ActiveSupport::Concern
    include Accessor

    module TypeMethods
      def define_id_methods(clazz, name, conf)
        validate_conf!(conf)

        if conf[:on]
          define_custom_method(clazz, name, conf[:on])
        elsif conf[:auto]
          define_uuid_method(clazz, name)
        elsif conf.empty?
          define_property_method(clazz, name)
        end
      end

      private

      def validate_conf!(conf)
        fail "Expected a Hash, got #{conf.class} (#{conf}) for id_property" if !conf.is_a?(Hash)

        return if conf[:on]

        if conf[:auto]
          fail "only :uuid auto id_property allowed, got #{conf[:auto]}" if conf[:auto] != :uuid
          return
        end

        return if conf.empty?

        fail "Illegal value #{conf.inspect} for id_property, expected :on or :auto"
      end

      def define_property_method(clazz, name)
        clear_methods(clazz, name)

        clazz.module_eval(%(
          def id
            _persisted_obj ? #{name.to_sym == :id ? 'attribute(\'id\')' : name} : nil
          end

          property :#{name}
                ), __FILE__, __LINE__)
      end


      def define_uuid_method(clazz, name)
        clear_methods(clazz, name)

        clazz.module_eval(%(
          default_property :#{name} do
             ::SecureRandom.uuid
          end

          def #{name}
             default_property_value
          end

          alias_method :id, :#{name}
                ), __FILE__, __LINE__)
      end

      def define_custom_method(clazz, name, on)
        clear_methods(clazz, name)

        clazz.module_eval(%{
          default_property :#{name} do |instance|
            raise "Specifying custom id_property #{name} on non-existent method #{on}" unless instance.respond_to?(:#{on})
            instance.#{on}
          end

          def #{name}
            default_property_value
          end

          alias_method :id, :#{name}
        }, __FILE__, __LINE__)
      end

      def clear_methods(clazz, name)
        clazz.module_eval(%(undef_method :#{name}), __FILE__, __LINE__) if clazz.method_defined?(name)
        clazz.module_eval(%(undef_property :#{name}), __FILE__, __LINE__) if clazz.attribute_names.include?(name.to_s)
      end

      extend self
    end


    module ClassMethods
      attr_accessor :manual_id_property

      def find_by_neo_id(id)
        Neo4j::Node.load(id)
      end

      def find_by_id(id)
        all.where(id_property_name => id).first
      end

      def find_by_ids(ids)
        all.where(id_property_name => ids).to_a
      end

      def id_property(name, conf = {})
        self.manual_id_property = true
        Neo4j::Session.on_next_session_available do |_|
          @id_property_info = {name: name, type: conf}
          TypeMethods.define_id_methods(self, name, conf)
          constraint(name, type: :unique) unless conf[:constraint] == false
        end
      end

      # rubocop:disable Style/PredicateName
      def has_id_property?
        ActiveSupport::Deprecation.warn 'has_id_property? is deprecated and may be removed from future releases, use id_property? instead.', caller

        id_property?
      end
      # rubocop:enable Style/PredicateName

      def id_property?
        id_property_info && !id_property_info.empty?
      end

      def id_property_info
        @id_property_info ||= {}
      end

      def id_property_name
        id_property_info[:name]
      end

      def manual_id_property?
        !!manual_id_property
      end

      alias_method :primary_key, :id_property_name

      private

      def id_property_constraint(name)
        if id_property?
          unless mapped_label.uniqueness_constraints[:property_keys].include?([name])
            # Neo4j Embedded throws a crazy error when a constraint can't be dropped
            drop_constraint(id_property_name, type: :unique) if constraint?(mapped_label_name, id_property_name)
          end
        end
      rescue Neo4j::Server::CypherResponse::ResponseError, Java::OrgNeo4jCypher::CypherExecutionException
      end
    end
  end
end
