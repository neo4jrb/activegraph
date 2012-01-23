module Neo4j
  module Batch

    # = Batch Insert
    # Neo4j has a batch insert mode that drops support for transactions and concurrency in favor of insertion speed.
    # This is useful when you have a big dataset that needs to be loaded once. In our experience, the batch inserter will
    # typically inject data around five times faster than running in normal transactional mode.
    #
    # Be aware that the BatchInserter is intended use is for initial import of data
    # * non thread safe
    # * non transactional
    # * failure to successfully invoke shutdown (properly) results in corrupt database files
    #
    class Inserter
      attr_reader :batch_inserter, :batch_indexer
      include ToJava
      include Neo4j::Load

      # Creates a new batch inserter.
      # Will raise an exception if Neo4j is already running at the same storage_path
      # 
      def initialize(storage_path=Neo4j.config.storage_path, config={})
        # check if neo4j is running and using the same storage path
        raise "Not allowed to start batch inserter while Neo4j is already running at storage location #{storage_path}" if Neo4j.storage_path == storage_path
        @batch_inserter  = org.neo4j.kernel.impl.batchinsert.BatchInserterImpl.new(storage_path, config)
        Indexer.index_provider  = org.neo4j.index.impl.lucene.LuceneBatchInserterIndexProvider.new(@batch_inserter)
        @rule_inserter = RuleInserter.new(self)
      end

      def running?
        @batch_inserter != nil
      end

      # This method MUST be called after inserting is completed.
      def shutdown
        @batch_inserter && @batch_inserter.shutdown
        @batch_inserter = nil
        @rule_inserter = nil
        
        Indexer.index_provider
        Indexer.index_provider && Indexer.index_provider.shutdown
        Indexer.index_provider = nil
        Indexer.clear_all_instances
      end

      # Creates a node. Returns a Fixnum id of the created node.
      # Adds a lucene index if there is a lucene index declared on the properties
      def create_node(props=nil, clazz = Neo4j::Node)
        props = {} if clazz != Neo4j::Node && props.nil?
        props['_classname'] = clazz.to_s if clazz != Neo4j::Node

        props = ensure_valid_props(props)

        node = @batch_inserter.create_node(props)
        props && _index(node, props, clazz)
        @rule_inserter.node_added(node, props)
        node
      end

      # returns true if the node exists
      def node_exist?(id)
        @batch_inserter.node_exists(id)
      end

      def ref_node
        @batch_inserter.get_reference_node
      end

      # creates a relationship between given nodes of given type.
      # Returns a fixnum id of the created relationship.
      def create_rel(rel_type, from_node, to_node, props=nil, clazz=Neo4j::Relationship)
        props = {} if clazz != Neo4j::Relationship && props.nil?
        props['_classname'] = clazz.to_s if clazz != Neo4j::Relationship

        props = ensure_valid_props(props)

        rel = @batch_inserter.create_relationship(from_node, to_node, type_to_java(rel_type), props)

        props && _index(rel, props, clazz)

        from_props = node_props(from_node)

        if from_props['_classname']
          from_class = to_class(from_props['_classname'])
          indexer = Indexer.instance_for(from_class)
          indexer.index_node_via_rel(rel_type, to_node, from_props)
        end

        to_props   = node_props(to_node)
        if to_props['_classname']
          to_class = to_class(to_props['_classname'])
          indexer = Indexer.instance_for(to_class)
          indexer.index_node_via_rel(rel_type, from_node, to_props)
        end
        rel
      end

      # Return a hash of all properties of given node
      def node_props(node)
        @batch_inserter.get_node_properties(node)
      end

      # Sets the properties of the given node, overwrites old properties
      def set_node_props(node, hash, clazz = Neo4j::Node)
        @batch_inserter.set_node_properties(node, hash)
        _index(node, hash, clazz)
      end

      # Sets the old properties of the given relationship, overwrites old properties
      def set_rel_props(rel, hash)
        @batch_inserter.set_relationship_properties(rel, hash)
      end

      # Returns the properties of the given relationship
      def rel_props(rel)
        @batch_inserter.get_relationship_properties(rel)
      end
      
      # Returns all the relationships of the given node
      def rels(node)
        @batch_inserter.getRelationships(node)
      end

      #  Makes sure additions/updates can be seen by #index_get and #index_query
      # so that they are guaranteed to return correct results.
      def index_flush(clazz = Neo4j::Node)
        indexer = Indexer.instance_for(clazz)
        indexer.index_flush
      end

      #  Returns matches from the index specified by index_type and class.
      #
      # ==== Parameters
      # * key :: the lucene key
      # * value :: the lucene value we look for given the key
      # * index_type :: :exact or :fulltext
      # * clazz :: on which clazz we want to perform the query
      #
      def index_get(key, value, index_type = :exact, clazz = Neo4j::Node)
        indexer = Indexer.instance_for(clazz)
        indexer.index_get(key, value, index_type)
      end

      #  Returns matches from the index specified by index_type and class.
      #
      # ==== Parameters
      # * query :: lucene query
      # * index_type :: :exact or :fulltext
      # * clazz :: on which clazz we want to perform the query
      #
      def index_query(query, index_type = :exact, clazz = Neo4j::Node)
        indexer = Indexer.instance_for(clazz)
        indexer.index_query(query, index_type)
      end

      # index the given entity (a node or a relationship)
      def _index(entity, props, clazz = Neo4j::Node) #:nodoc:
        indexer = Indexer.instance_for(clazz)
        indexer.index_entity(entity, props)
      end


      # hmm, maybe faster not wrapping this ?
      def to_java_map(hash)
        return nil if hash.nil?
        map = java.util.HashMap.new
        hash.each_pair do |k, v|
          case v
            when Symbol
              map[k.to_s] = v.to_s
            else
              map[k.to_s] = v
          end
        end
        map
      end
    end
  end
end
