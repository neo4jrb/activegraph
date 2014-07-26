module Neo4j::ActiveNode

  module IdProperty
    extend ActiveSupport::Concern


    module TypeMethods
      def define_id_methods(clazz, name, conf)
        validate_conf(conf)
        if conf[:on]
          define_custom_method(clazz, name, conf[:on])
        elsif conf[:auto]
          raise "only :uuid auto id_property allowed, got #{conf[:auto]}" unless conf[:auto] == :uuid
          define_uuid_method(clazz, name)
        else conf.empty?
          define_property_method(clazz, name)
        end
      end

      private

      def validate_conf(conf)
        return if conf.empty?

        raise "Expected a Hash, got #{conf.class} (#{conf.to_s}) for id_property" unless conf.is_a?(Hash)

        unless conf.include?(:auto) || conf.include?(:on)
          raise "Illegal value #{conf.inspect} for id_property, expected :on or :auto"
        end
      end

      def define_property_method(clazz, name)
        clazz.module_eval(%Q{
          def id
            persisted? ? #{name} : nil
          end

          property :#{name}
          validates_uniqueness_of :#{name}
        }, __FILE__, __LINE__)
      end


      def define_uuid_method(clazz, name)
        clazz.module_eval(%Q{
          default_property :#{name} do
             ::SecureRandom.uuid
          end

          def #{name}
             default_property :#{name}
          end

          alias_method :id, :#{name}
        }, __FILE__, __LINE__)
      end

      def define_custom_method(clazz, name, on)
        clazz.module_eval(%Q{
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

      extend self
    end


    module ClassMethods

      def find_by_id(key, session = Neo4j::Session.current!)
        Neo4j::Node.load(key.to_i, session)
      end


      def id_property(name, conf = {})
        TypeMethods.define_id_methods(self, name, conf)

        constraint name, type: :unique

        self.define_singleton_method(:find_by_id) do |key|
          self.where(name => key).first
        end
      end

    end

  end

end
