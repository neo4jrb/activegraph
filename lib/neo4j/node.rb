module Neo4j


  # See http://wiki.neo4j.org/content/Indexing_with_IndexService
  module Index
    def index(field, db=Neo4j.db)
      db.lucene.index(self, field.to_s, self[field])
    end

    def rm_index(field, db=Neo4j.db)
      db.lucene.remove_index(self, field.to_s)
    end

  end


  module Equal
    def equal?(o)
      eql?(o)
    end

    def eql?(o)
      return false unless o.respond_to?(:id)
      o.id == id
    end

    def ==(o)
      eql?(o)
    end
  end

  module Property

    def property?(key)
      has_property?(key.to_s)
    end

    def [](key)
      return unless property?(key)
      get_property(key.to_s)
    end

    def []=(key, value)
      k = key.to_s
      if value.nil?
        delete_property(k)
      else
        set_property(k, value)
      end
    end
  end

  class NodeTraverser
    include Enumerable

    def initialize(from, type, dir)
      @type = org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
      @from = from
      @td = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new
      @td.breadth_first()
      @td.relationships(@type)
    end

    def <<(other_node)
      @from.create_relationship_to(other_node, @type)
    end

    def first
      find { true }
    end

    def each
      iter = iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end

    def iterator
      iter = @td.traverse(@from).nodes.iterator
      iter.next if iter.hasNext
      # don't include the first node'
      iter
    end
  end

  module Relationship
    def outgoing(type)
      NodeTraverser.new(self, type, :outgoing)
    end
  end


  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    include Neo4j::Property
    include Neo4j::Relationship
    include Neo4j::Equal
    include Neo4j::Index
  end


  class Node

    class << self
      def new(*args)
        # creates a new node using the default db instance when given no args

        # the first argument can be an hash of properties to set
        props = args[0].respond_to?(:each_pair) && args[0]

        # a db instance can be given, is the first argument if that was not a hash, or otherwise the second
        db = (!props && args[0]) || args[1] || Neo4j.db
        create(props, db)
      end

      def create(props, db = Neo4j.db)
        node = db.graph.create_node
        props.each_pair { |k, v| node.set_property(k.to_s, v) } if props
        node
      end


      def load(node_id, db = Neo4j.db)
        db.graph.get_node_by_id(node_id.to_i)
      rescue org.neo4j.graphdb.NotFoundException
        nil
      end

      def exist?(node_or_node_id, db = Neo4j.db)
        id = node_or_node_id.respond_to?(:id) ? node_or_node_id.id : node_or_node_id
        load(id, db) != nil
      end

      def find(field, query, db=Neo4j.db)
        db.lucene.get_nodes(field.to_s, query)
      end

      # Adds a global index. Will use the event framework in order to keep the property in sync with
      # the lucene database
      def index(field, db=Neo4j.db)
        db.index(field)
      end

      def rm_index(field, db=Neo4j.db)
        db.rm_index(field)
      end
    end
  end
end