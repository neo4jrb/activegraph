module Neo4j::ActiveNode
  module Enum
    extend ActiveSupport::Concern
    include Neo4j::Shared::Enum

    module ClassMethods
      def method_missing(name, *args, &block)
        singular_name = name.to_s.singularize.to_sym
        if args.empty? && !block && @neo4j_enum_data[singular_name]
          @neo4j_enum_data[singular_name]
        else
          super
        end
      end

      protected

      def build_property_options(enum_keys, options = {})
        if options[:_index]
          super.merge(index: :exact)
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
