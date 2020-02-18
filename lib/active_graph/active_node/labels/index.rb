module ActiveGraph::ActiveNode::Labels
  module Index
    extend ActiveSupport::Concern

    module ClassMethods
      extend Forwardable

      def_delegators :declared_properties, :indexed_properties

      # Creates a Neo4j index on given property
      #
      # This can also be done on the property directly, see ActiveGraph::ActiveNode::Property::ClassMethods#property.
      #
      # @param [Symbol] property the property we want a Neo4j index on
      #
      # @example
      #   class Person
      #      include ActiveGraph::ActiveNode
      #      property :name
      #      index :name
      #    end
      def index(property)
        return if ActiveGraph::ModelSchema.defined_constraint?(self, property)

        ActiveGraph::ModelSchema.add_defined_index(self, property)
      end

      # Creates a neo4j constraint on this class for given property
      #
      # @example
      #   Person.constraint :name, type: :unique
      def constraint(property, _constraints = {type: :unique})
        ActiveGraph::ModelSchema.add_defined_constraint(self, property)
      end
    end
  end
end
