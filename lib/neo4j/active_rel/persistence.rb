
module Neo4j::ActiveRel
  module Persistence
    extend ActiveSupport::Concern
    include Neo4j::Shared::Persistence

    attr_writer :from_node_identifier, :to_node_identifier
    NODE_SYMBOLS = [:from_node, :to_node]

    class RelInvalidError < RuntimeError; end
    class ModelClassInvalidError < RuntimeError; end
    class RelCreateFailedError < RuntimeError; end

    def from_node_identifier
      @from_node_identifier || :from_node
    end

    def to_node_identifier
      @to_node_identifier || :to_node
    end

    def cypher_identifier
      @cypher_identifier || :r
    end

    def save(*)
      create_or_update
    end

    def save!(*args)
      save(*args) or fail(RelInvalidError, self) # rubocop:disable Style/AndOr
    end

    def create_model
      validate_node_classes!
      rel = _create_rel(props_for_create)
      return self unless rel.respond_to?(:_persisted_obj)
      init_on_load(rel._persisted_obj, from_node, to_node, @rel_type)
      true
    end

    module ClassMethods
      # Creates a new relationship between objects
      # @param [Hash] props the properties the new relationship should have
      def create(props = {})
        relationship_props = extract_association_attributes!(props) || {}
        new(props).tap do |obj|
          relationship_props.each do |prop, value|
            obj.send("#{prop}=", value)
          end
          obj.save
        end
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(*args)
        props = args[0] || {}
        relationship_props = extract_association_attributes!(props) || {}
        new(props).tap do |obj|
          relationship_props.each do |prop, value|
            obj.send("#{prop}=", value)
          end
          obj.save!
        end
      end

      def create_method
        creates_unique? ? :create_unique : :create
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

    def _create_rel(props = {})
      _rel_creation_query(props)
    end

    def _rel_creation_query(props)
      Neo4j::Transaction.run do
        node_before_callbacks! do
          res = query_factory(props).query.return(*return_values).first
          node_symbols.each { |n| wrap!(send(n), res, n) }
          res.r
        end
      end
    end

    def query_factory(props)
      Neo4j::Shared::QueryFactory.create(self, props, :r).tap do |rel_query|
        rel_query.base_query = iterative_query
      end
    end

    def iterative_query
      node_symbols.inject(nil) do |iterative_query, sym|
        obj = send(sym)
        Neo4j::Shared::QueryFactory.create(obj, obj.props_for_create, sym).tap do |new_query|
          new_query.base_query = iterative_query if iterative_query
        end
      end
    end

    def wrap!(node, res, key)
      return if node.persisted? || !res.respond_to?(key)
      unwrapped = res.send(key)
      node.init_on_load(unwrapped, unwrapped.props)
    end

    def return_values
      [:r].tap do |result|
        node_symbols.each { |k| result << k unless send(k).persisted? }
      end
    end

    def node_symbols
      self.class::NODE_SYMBOLS
    end

    def node_before_callbacks!
      from_node.conditional_callback(:create, from_node.persisted?) do
        to_node.conditional_callback(:create, to_node.persisted?) do
          yield
        end
      end
    end
  end
end
