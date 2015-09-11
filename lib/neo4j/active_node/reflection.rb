module Neo4j::ActiveNode
  # A reflection contains information about an association.
  # They are often used in connection with form builders to determine associated classes.
  # This module contains methods related to the creation and retrieval of reflections.
  module Reflection
    extend ActiveSupport::Concern

    included do
      class_attribute :reflections
      self.reflections = {}
    end

    # Adds methods to the class related to creating and retrieving reflections.
    module ClassMethods
      # @param macro [Symbol] the association type, :has_many or :has_one
      # @param name [Symbol] the association name
      # @param association_object [Neo4j::ActiveNode::HasN::Association] the association object created in the course of creating this reflection
      def create_reflection(macro, name, association_object, model)
        self.reflections = self.reflections.merge(name => AssociationReflection.new(macro, name, association_object))
        association_object.add_destroy_callbacks(model)
      end

      private :create_reflection
      # @param association [Symbol] an association declared on the model
      # @return [Neo4j::ActiveNode::Reflection::AssociationReflection] of the given association
      def reflect_on_association(association)
        reflections[association.to_sym]
      end

      # Returns an array containing one reflection for each association declared in the model.
      def reflect_on_all_associations(macro = nil)
        association_reflections = reflections.values
        macro ? association_reflections.select { |reflection| reflection.macro == macro } : association_reflections
      end
    end

    # The actual reflection object that contains information about the given association.
    # These should never need to be created manually, they will always be created by declaring a :has_many or :has_one association on a model.
    class AssociationReflection
      # The name of the association
      attr_reader :name

      # The type of association
      attr_reader :macro

      # The association object referenced by this reflection
      attr_reader :association

      def initialize(macro, name, association)
        @macro        = macro
        @name         = name
        @association  = association
      end

      # Returns the target model
      def klass
        @klass ||= class_name.constantize
      end

      # Returns the name of the target model
      def class_name
        @class_name ||= association.target_class.name
      end

      def rel_klass
        @rel_klass ||= rel_class_name.constantize
      end

      def rel_class_name
        @rel_class_name ||= association.relationship_class.name.to_s
      end

      def type
        @type ||= association.relationship_type
      end

      def collection?
        macro == :has_many
      end

      def validate?
        true
      end
    end
  end
end
