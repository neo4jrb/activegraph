module ActiveGraph
  # Makes Neo4j Relationships more or less act like ActiveRecord objects.
  # See documentation at https://github.com/neo4jrb/neo4j/wiki/Neo4j%3A%3AActiveRel
  module Relationship
    extend ActiveSupport::Concern

    MARSHAL_INSTANCE_VARIABLES = [:@attributes, :@type, :@_persisted_obj]

    include ActiveGraph::Shared
    include ActiveGraph::Relationship::Initialize
    include ActiveGraph::Shared::Identity
    include ActiveGraph::Shared::Marshal
    include ActiveGraph::Shared::SerializedProperties
    include ActiveGraph::Relationship::Property
    include ActiveGraph::Relationship::Persistence
    include ActiveGraph::Relationship::Validations
    include ActiveGraph::Relationship::Callbacks
    include ActiveGraph::Relationship::Query
    include ActiveGraph::Relationship::Types
    include ActiveGraph::Shared::Enum
    include ActiveGraph::Shared::PermittedAttributes
    include ActiveGraph::Transactions

    class FrozenRelError < ActiveGraph::Error; end

    def initialize(from_node = nil, to_node = nil, args = nil)
      load_nodes(node_or_nil(from_node), node_or_nil(to_node))
      resolved_args = hash_or_nil(from_node, args)
      symbol_args = sanitize_input_parameters(resolved_args)
      super(symbol_args)
    end

    def node_cypher_representation(node)
      node_class = node.class
      id_name = node_class.id_property_name
      labels = ':' + node_class.mapped_label_names.join(':')

      "(#{labels} {#{id_name}: #{node.id.inspect}})"
    end

    def neo4j_obj
      _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
    end

    included do
      include ActiveGraph::Timestamps if ActiveGraph::Config[:record_timestamps]

      def self.inherited(other)
        attributes.each_pair do |k, v|
          other.inherit_property k.to_sym, v.clone, declared_properties[k].options
        end
        super
      end
    end

    ActiveSupport.run_load_hooks(:relationship, self)

    private

    def node_or_nil(node)
      node.is_a?(ActiveGraph::Node) || node.is_a?(Integer) ? node : nil
    end

    def hash_or_nil(node_or_hash, hash_or_nil)
      hash_or_parameter?(node_or_hash) ? node_or_hash : hash_or_nil
    end
  end
end
