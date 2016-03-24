module Neo4j
  # Makes Neo4j Relationships more or less act like ActiveRecord objects.
  # See documentation at https://github.com/neo4jrb/neo4j/wiki/Neo4j%3A%3AActiveRel
  module ActiveRel
    extend ActiveSupport::Concern

    MARSHAL_INSTANCE_VARIABLES = [:@attributes, :@rel_type, :@_persisted_obj]

    include Neo4j::Shared
    include Neo4j::ActiveRel::Initialize
    include Neo4j::Shared::Identity
    include Neo4j::Shared::Marshal
    include Neo4j::Shared::SerializedProperties
    include Neo4j::ActiveRel::Property
    include Neo4j::ActiveRel::Persistence
    include Neo4j::ActiveRel::Validations
    include Neo4j::ActiveRel::Callbacks
    include Neo4j::ActiveRel::Query
    include Neo4j::ActiveRel::Types
    include Neo4j::Shared::Enum

    class FrozenRelError < Neo4j::Error; end

    def initialize(from_node = nil, to_node = nil, args = nil)
      load_nodes(node_or_nil(from_node), node_or_nil(to_node))
      resolved_args = hash_or_nil(from_node, args)
      symbol_args = resolved_args.is_a?(Hash) ? resolved_args.symbolize_keys : resolved_args
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
      include Neo4j::Timestamps if Neo4j::Config[:record_timestamps]

      def self.inherited(other)
        attributes.each_pair do |k, v|
          other.inherit_property k.to_sym, v.clone, declared_properties[k].options
        end
        super
      end
    end

    ActiveSupport.run_load_hooks(:active_rel, self)

    private

    def node_or_nil(node)
      node.is_a?(Neo4j::ActiveNode) || node.is_a?(Integer) ? node : nil
    end

    def hash_or_nil(node_or_hash, hash_or_nil)
      node_or_hash.is_a?(Hash) ? node_or_hash : hash_or_nil
    end

    module ClassMethods
      [:create, :create!].each do |meth|
        define_method(meth) do |from_node_or_args = nil, to_node = nil, args = nil|
          return super(from_node_or_args) if from_node_or_args.is_a?(Hash)
          args_hash = args || {}
          args_with_node!(:from_node, from_node_or_args, args_hash)
          args_with_node!(:to_node, to_node, args_hash)
          super(args_hash)
        end
      end

      private

      def args_with_node!(key, node, args)
        args[key] = node if node.is_a?(Neo4j::ActiveNode)
        args
      end
    end
  end
end
