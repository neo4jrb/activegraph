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
      increment_by_query! query_as(:r), attribute, by, :r
    end

    def create_model
      validate_node_classes!
      validate_has_one_rel
      rel = _create_rel
      return self unless rel.respond_to?(:props)
      init_on_load(rel, from_node, to_node, @rel_type)
      true
    end

    def validate_has_one_rel
      return unless Neo4j::Config[:enforce_has_one]
      to_node.validate_reverse_has_one_active_rel(self, :in, from_node) if to_node.persisted?
      from_node.validate_reverse_has_one_active_rel(self, :out, to_node) if from_node.persisted?
    end

    def query_as(var)
      # This should query based on the nodes, not the rel neo_id, I think
      # Also, picky point: Should the var be `n`?
      self.class.query_as(neo_id, var)
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
        query_as(id).pluck(:r).first
      end

      def query_as(neo_id, var = :r)
        Neo4j::ActiveBase.new_query.match("()-[#{var}]->()").where(var => {neo_id: neo_id})
      end
    end

    def create_method
      self.class.create_method
    end

    private

    def destroy_query
      query_as(:r).delete(:r)
    end

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
