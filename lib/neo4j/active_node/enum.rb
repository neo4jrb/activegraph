module Neo4j::ActiveNode
  module Enum
    extend ActiveSupport::Concern
    include Neo4j::Shared::Enum

    module ClassMethods
      protected

      def build_property_options(enum_keys, options = {})
        if options[:_index]
          super.merge!(index: :exact)
        else
          super
        end
      end

      def define_enum_methods(property_name, enum_keys, options)
        super
        define_enum_scopes(property_name, enum_keys)
      end

      def define_enum_scopes(property_name, enum_keys)
        enum_keys.keys.each do |name|
          scope name, -> { where(property_name => name) }
        end
      end
    end
  end
end
