module Neo4j::ActiveNode
  module Enum
    extend ActiveSupport::Concern
    include Neo4j::Shared::Enum

    module ClassMethods
      protected

      def define_property(property_name, *args)
        super
        Neo4j::ModelSchema.add_required_index(self, property_name) unless args[1][:_index] == false
      end

      def define_enum_methods(property_name, enum_keys, options)
        super
        define_enum_scopes(property_name, enum_keys)
      end

      def define_enum_scopes(property_name, enum_keys)
        enum_keys.each_key do |name|
          scope name, -> { where(property_name => name) }
        end
      end
    end
  end
end
