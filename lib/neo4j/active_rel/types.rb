module Neo4j
  module ActiveRel

    # provides mapping of type to model name
    module Types
      extend ActiveSupport::Concern
      WRAPPED_CLASSES = {}

      included do |klazz|
        type self.name, true
      end

      module ClassMethods

        # @param type [String] sets the relationship type when creating relationships via this class
        def type(given_type = self.name, auto = false)
          use_type = auto ? "##{given_type.underscore.downcase}" : given_type
          mapped_type_name use_type
          @rel_type = use_type
        end

        # @return [String] a string representing the relationship type that will be created
        def _type
          @rel_type
        end

        def add_wrapped_class(type)
          _wrapped_classes[type.to_sym.downcase] = self.name
        end

        def _wrapped_classes
          Neo4j::ActiveRel::Types::WRAPPED_CLASSES
        end

        def mapped_type_name(type)
          add_wrapped_class(type)
        end
      end
    end
  end
end
