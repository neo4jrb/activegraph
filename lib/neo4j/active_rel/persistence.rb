module Neo4j::ActiveRel
  module Persistence
    extend ActiveSupport::Concern
    include Neo4j::Shared::Cypher::RelIdentifiers
    include Neo4j::Shared::Persistence

    class RelInvalidError < RuntimeError; end
    class ModelClassInvalidError < RuntimeError; end
    class RelCreateFailedError < RuntimeError; end

    def from_node_identifier
      @from_node_identifier || :from_node
    end

    def to_node_identifier
      @to_node_identifier || :to_node
    end

    def from_node_identifier=(id)
      @from_node_identifier = id.to_sym
    end

    def to_node_identifier=(id)
      @to_node_identifier = id.to_sym
    end

    def cypher_identifier
      @cypher_identifier || :rel
    end

    def save(*)
      create_or_update
    end

    def save!(*args)
      save(*args) or fail(RelInvalidError, inspect) # rubocop:disable Style/AndOr
    end

    # Increments concurrently a numeric attribute by a centain amount
    # @param [Symbol, String] name of the attribute to increment
    # @param [Integer, Float] amount to increment
    def concurrent_increment!(attribute, by = 1)
      query_rel = Neo4j::Session.query.match('()-[n]-()').where(n: {neo_id: neo_id})
      increment_by_query! query_rel, attribute, by
    end

    def create_model
      validate_node_classes!
      rel = _create_rel
      return self unless rel.respond_to?(:props)
      init_on_load(rel, from_node, to_node, @rel_type)
      true
    end

    module ClassMethods
      # Creates a new relationship between objects
      # @param [Hash] props the properties the new relationship should have
      def create(*args)
        new(*args).tap(&:save)
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(*args)
        new(*args).tap(&:save!)
      end

      def create_method
        creates_unique? ? :create_unique : :create
      end

      def load_entity(id)
        Neo4j::Relationship.load(id)
      end
    end

    def create_method
      self.class.create_method
    end

    private

    def validate_node_classes!
      [from_node, to_node].each do |node|
        type = from_node == node ? :_from_class : :_to_class
        type_class = self.class.send(type)

        unless valid_type?(type_class, node)
          fail ModelClassInvalidError, type_validation_error_message(node, type_class)
        end
      end
    end

    def valid_type?(type_object, node)
      case type_object
      when false, :any
        true
      when Array
        type_object.any? { |c| valid_type?(c, node) }
      else
        node.class.mapped_label_names.include?(type_object.to_s.constantize.mapped_label_name)
      end
    end

    def type_validation_error_message(node, type_class)
      "Node class was #{node.class} (#{node.class.object_id}), expected #{type_class} (#{type_class.object_id})"
    end

    def _create_rel
      factory = QueryFactory.new(from_node, to_node, self)
      factory.build!
      factory.unwrapped_rel
    end
  end
end
