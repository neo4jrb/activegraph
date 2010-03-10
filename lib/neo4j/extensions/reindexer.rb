module Neo4j

  module PropertyClassMethods
      # Traverse all nodes and update the lucene index.
      # Can be used for example if it is neccessarly to change the index on a class
      #
      def update_index
        all.nodes.each do |n|
          n.update_index
        end
      end

      # Returns node instances of this class.
      #
      def all
        index_node = IndexNode.instance
        index_node.rels.outgoing(self)
      end
  end
  
  module NodeMixin
    alias_method :ignore_incoming_cascade_delete_orig?, :ignore_incoming_cascade_delete?
    def ignore_incoming_cascade_delete? (relationship)
      # if it's an index node relationship then it should be allowed to cascade delete the node
      ignore_incoming_cascade_delete_orig?(relationship) || relationship.other_node(self) == IndexNode.instance
    end

  end


  class IndexNode
    include NodeMixin

    # Connects the given node with the reference node.
    # The type of the relationship will be the same as the class name of the
    # specified node unless the optional parameter type is specified.
    # This method is used internally to keep a reference to all node instances in the node space
    # (useful for example for reindexing all nodes by traversing the node space).
    #
    # ==== Parameters
    # node<Neo4j::NodeMixin>:: Connect the reference node with this node
    # type<String>:: Optional, the type of the relationship we want to create
    #
    # ==== Returns
    # nil
    #
    # :api: private
    def connect(node, type = node.class.root_class)
      rtype = org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
      @_java_node.createRelationshipTo(node._java_node, rtype)
      nil
    end

    def on_node_created(node)
      # we have to avoid connecting to our self
      unless self == node
        node.class.ancestors.grep(Class).each{|p| connect(node, p) if p.respond_to?(:all)}
      end
    end

    def self.on_neo_started(neo_instance)
      if neo_instance.ref_node.rel?(:index_node)
        # we already have it, put it in instance variable so we do not have to look again
        @index_node = neo_instance.ref_node.rels.outgoing(:index_node).nodes.first
      else
        @index_node = IndexNode.new # cache this so we do not have to look it up always
        neo_instance.ref_node.rels.outgoing(:index_node) << @index_node
      end
      Neo4j.event_handler.add(@index_node)
    end

    def self.on_neo_stopped(neo_instance)
      # unregister the instance
      Neo4j.event_handler.remove(@index_node)
      @index_node = nil
    end

    def self.instance
      Neo4j.start if @index_node.nil?
      @index_node
    end

    def self.instance?
      !@index_node.nil?
    end

  end


  # Add this so it can add it self as listener
  def self.load_reindexer
    Neo4j.event_handler.add(IndexNode)
    # in case we already have started
    Neo4j::Transaction.run { IndexNode.on_neo_started(Neo4j) } if Neo4j.running?
  end

  def self.unload_reindexer
    Neo4j.event_handler.remove(IndexNode)
    Neo4j.event_handler.remove(IndexNode.instance) if IndexNode.instance?
  end


  load_reindexer
end
