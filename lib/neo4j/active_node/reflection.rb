module Neo4j::ActiveNode
  module Reflection
    extend ActiveSupport::Concern

    included do
      class_attribute :reflections
      self.reflections = {}
    end

    module ClassMethods

      def create_reflection(macro, name, association_object)
        self.reflections = self.reflections.merge(name => AssociationReflection.new(macro, name, association_object))
      end

      def reflect_on_association(association)
        reflections[association.to_sym]
      end

      def reflect_on_all_associations(macro = nil)
        association_reflections = reflections.values
        macro ? association_reflections.select { |reflection| reflection.macro == macro } : association_reflections
      end
    end

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