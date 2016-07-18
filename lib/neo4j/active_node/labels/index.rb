module Neo4j::ActiveNode::Labels
  module Index
    extend ActiveSupport::Concern

    module ClassMethods
      extend Forwardable

      def_delegators :declared_properties, :indexed_properties

      # Creates a Neo4j index on given property
      #
      # This can also be done on the property directly, see Neo4j::ActiveNode::Property::ClassMethods#property.
      #
      # @param [Symbol] property the property we want a Neo4j index on
      #
      # @example
      #   class Person
      #      include Neo4j::ActiveNode
      #      property :name
      #      index :name
      #    end
      def index(property)
        declared_properties.index_or_fail!(property, id_property_name)
        schema_create_operation(:index, property)
      end

      # Creates a neo4j constraint on this class for given property
      #
      # @example
      #   Person.constraint :name, type: :unique
      def constraint(property, _constraints = {type: :unique})
        fail <<MSG

          Constraints defined on models are no longer supported.  To ensure that you have this index you can generate a migration:

#{Neo4j::ActiveBase.force_add_index_message(self.name, property)}
MSG
      end

      # @param [Symbol] property The name of the property index to be dropped
      def drop_index(property, options = {})
        declared_properties[property].unindex! if declared_properties[property]
        schema_drop_operation(:index, property, options)
      end

      # @param [Symbol] property The name of the property constraint to be dropped
      # @param [Hash] constraint The constraint type to be dropped.
      def drop_constraint(property, constraint = {type: :unique})
        declared_properties[property].unconstraint! if declared_properties[property]
        schema_drop_operation(:constraint, property, constraint)
      end

      def index?(property)
        ensure_id_property_info!

        mapped_label.indexes.include?([property])
      end

      def constraint?(property)
        ensure_id_property_info!

        mapped_label.uniqueness_constraints.include?([property])
      end

      private

      def schema_create_operation(type, property, options = {})
        new_schema_class(type, property, options).create!
      end

      def schema_drop_operation(type, property, options = {})
        new_schema_class(type, property, options).drop!
      end

      def new_schema_class(type, property, options)
        case type
        when :index
          Neo4j::Schema::ExactIndexOperation
        when :constraint
          Neo4j::Schema::UniqueConstraintOperation
        else
          fail "Unknown Schema Operation class #{type}"
        end.new(mapped_label, property, options)
      end
    end
  end
end
