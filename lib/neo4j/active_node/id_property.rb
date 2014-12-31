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
  module IdProperty
    extend ActiveSupport::Concern


    module TypeMethods
      def define_id_methods(clazz, name, conf)
        fail "Expected a Hash, got #{conf.class} (#{conf}) for id_property" unless conf.is_a?(Hash)
        if conf[:on]
          define_custom_method(clazz, name, conf[:on])
        elsif conf[:auto]
          fail "only :uuid auto id_property allowed, got #{conf[:auto]}" unless conf[:auto] == :uuid
          define_uuid_method(clazz, name)
        elsif conf.empty?
          define_property_method(clazz, name)
        else
          fail "Illegal value #{conf.inspect} for id_property, expected :on or :auto"
        end
      end

      private

      def define_property_method(clazz, name)
        clear_methods(clazz, name)

        clazz.module_eval(%(
          def id
            _persisted_obj ? #{name.to_sym == :id ? 'attribute(\'id\')' : name} : nil
          end

          validates_uniqueness_of :#{name}

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
             default_property :#{name}
          end

          alias_method :id, :#{name}
                ), __FILE__, __LINE__)
      end

      def define_custom_method(clazz, name, on)
        clear_methods(clazz, name)

        clazz.module_eval(%{
          default_property :#{name} do |instance|
             raise "Specifying custom id_property #{name} on none existing method #{on}" unless instance.respond_to?(:#{on})
             instance.#{on}
          end

          def #{name}
             default_property :#{name}
          end

          alias_method :id, :#{name}
        }, __FILE__, __LINE__)
      end

      def clear_methods(clazz, name)
        if clazz.method_defined?(name)
          clazz.module_eval(%(
            undef_method :#{name}
                    ), __FILE__, __LINE__)
        end

        if clazz.attribute_names.include?(name.to_s)
          clazz.module_eval(%(
            undef_property :#{name}
                    ), __FILE__, __LINE__)
        end
      end

      extend self
    end


    module ClassMethods
      def find_by_neo_id(id)
        Neo4j::Node.load(id)
      end

      def find_by_id(id)
        self.where(id_property_name => id).first
      end

      def find_by_ids(ids)
        self.where(id_property_name => ids).to_a
      end

      def id_property(name, conf = {})
        begin
          if has_id_property?
            unless mapped_label.uniqueness_constraints[:property_keys].include?([name])
              drop_constraint(id_property_name, type: :unique)
            end
          end
        rescue Neo4j::Server::CypherResponse::ResponseError
        end

        @id_property_info = {name: name, type: conf}
        TypeMethods.define_id_methods(self, name, conf)
        constraint name, type: :unique

        self.define_singleton_method(:find_by_id) do |key|
          self.where(name => key).first
        end
      end

      def has_id_property?
        id_property_info && !id_property_info.empty?
      end

      def id_property_info
        @id_property_info ||= {}
      end

      def id_property_name
        id_property_info[:name]
      end

      alias_method :primary_key, :id_property_name
    end
  end
end
