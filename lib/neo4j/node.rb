module Neo4j

  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    include Neo4j::JavaPropertyMixin
    include Neo4j::JavaNodeMixin
    include Neo4j::JavaListMixin
  end

  # A node in the graph with properties and relationships to other entities. 
  # Along with relationships, nodes are the core building blocks of the Neo4j data representation model. 
  # Nodes are created by invoking the Neo4j::Node.new method.
  #
  # The new method of this class will return a Java org.neo4j.graphdb.Node
  #
  # === Included Mixins
  # * Neo4j::JavaPropertyMixin (operations that deal with relationships)
  # * Neo4j::JavaNodeMixin (operations that deal with properties
  # * Neo4j::JavaListMixin (operations that deals with list/timeline relationships)
  #
  # (Those mixin are actually not included in the Neo4j::Node but instead directly included in the java class org.neo4j.graphdb.Node)
  #
  # See also the Neo4j::NodeMixin if you want to wrap a node with your own Ruby class.
  #
  class Node
    class << self
      # Returns a org.neo4j.graphdb.Node java object (!)
      # Will trigger a event that the node was created.
      # 
      # === Parameters
      # *args :: can be a hash of properties to initialize the node with or empty
      #
      # === Returns
      # org.neo4j.graphdb.Node java object
      #
      # === Examples
      #
      #  Neo4j::Node.new
      #  Neo4j::Node.new :name => 'foo', :age => 100
      #
      def new(*args)
        node = Neo4j.create_node(args[0] || {})
        yield node if block_given?
        Neo4j.event_handler.node_created(node)
        node
      end
    end
  end

end
