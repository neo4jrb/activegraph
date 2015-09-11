module Neo4j
  # Makes Neo4j Relationships more or less act like ActiveRecord objects.
  # See documentation at https://github.com/neo4jrb/neo4j/wiki/Neo4j%3A%3AActiveRel
  module ActiveRel
    extend ActiveSupport::Concern

    include Neo4j::Shared
    include Neo4j::ActiveRel::Initialize
    include Neo4j::Shared::Identity
    include Neo4j::Shared::SerializedProperties
    include Neo4j::ActiveRel::Property
    include Neo4j::ActiveRel::Persistence
    include Neo4j::ActiveRel::Validations
    include Neo4j::ActiveRel::Callbacks
    include Neo4j::ActiveRel::Query
    include Neo4j::ActiveRel::Types

    class FrozenRelError < StandardError; end

    def initialize(*args)
      load_nodes
      super
    end

    def inspect
      attribute_pairs = attributes.sort.map { |key, value| "#{key}: #{value.inspect}" }
      attribute_descriptions = attribute_pairs.join(', ')
      separator = ' ' unless attribute_descriptions.empty?

      cypher_representation = "#{node_cypher_representation(from_node)}-[:#{type}]->#{node_cypher_representation(to_node)}"
      "#<#{self.class.name} #{cypher_representation}#{separator}#{attribute_descriptions}>"
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
        super
      end
    end

    ActiveSupport.run_load_hooks(:active_rel, self)
  end
end
