module Neo4j
  module ActiveRel
    # provides mapping of type to model name
    module Types
      extend ActiveSupport::Concern

      # WRAPPED_CLASSES maps relationship types to ActiveRel models.
      #
      # Typically, it's a 1:1 relationship, with a type having a model of the same name. Sometimes, someone needs to be a precious
      # snowflake and have a model name that doesn't match the rel type, so this comes in handy.
      #
      # As an example, Chris often finds it easier to name models after the classes that use the relationship: `StudentLesson` instead of
      # `EnrolledIn`, because it's easier to remember "A student has a relationship to lesson" than "the type of relationship between Student
      # and Lesson is 'EnrolledIn'." After all, that is a big part of why we have models, right? To make our lives easier?
      #
      # A model is added to WRAPPED_CLASSES when it is initalized AND when the `type` class method is called within a model. This means that
      # it's possible a model will be added twice: once with the rel_type version of the model name, again with the custom type. deal_with_it.gif.
      #
      # As an alternative to this, you can call the `set_classname` class method to insert a `_classname` property into your relationship,
      # which will completely bypass this whole process.
      WRAPPED_CLASSES = {}

      included do
        type self.namespaced_model_name, true
      end

      module ClassMethods
        include Neo4j::Shared::RelTypeConverters

        def inherited(subclass)
          subclass.type subclass.namespaced_model_name, true
        end

        # @param [String] given_type sets the relationship type when creating relationships via this class
        # @param [Boolean] auto Should the given_type be changed in compliance with the gem's rel decorator setting?
        # This option is used internally, users will usually ignore it.
        def type(given_type = nil, auto = false)
          return rel_type if given_type.nil?
          @rel_type = (auto ? decorated_rel_type(given_type) : given_type).tap do |type|
            add_wrapped_class(type) unless uses_classname?
          end
        end

        def namespaced_model_name
          case Neo4j::Config[:module_handling]
          when :demodulize
            self.name.demodulize
          when Proc
            Neo4j::Config[:module_handling].call(self.name)
          else
            self.name
          end
        end

        def rel_type
          @rel_type || type(namespaced_model_name, true)
        end

        # @return [String] a string representing the relationship type that will be created
        alias_method :_type, :rel_type # Should be deprecated

        def add_wrapped_class(type)
          # _wrapped_classes[type.to_sym.downcase] = self.name
          _wrapped_classes[type.to_sym] = self.name
        end

        def _wrapped_classes
          Neo4j::ActiveRel::Types::WRAPPED_CLASSES
        end
      end
    end
  end
end
