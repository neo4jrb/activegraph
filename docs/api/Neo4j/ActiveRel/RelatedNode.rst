RelatedNode
===========



A container for ActiveRel's :inbound and :outbound methods. It provides lazy loading of nodes.
It's important (or maybe not really IMPORTANT, but at least worth mentioning) that calling method_missing
will result in a query to load the node if the node is not already loaded.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   RelatedNode/UnsetRelatedNodeError

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/related_node.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/related_node.rb#L5>`_





Methods
-------



.. _`Neo4j/ActiveRel/RelatedNode#==`:

**#==**
  Loads the node if needed, then conducts comparison.

  .. code-block:: ruby

     def ==(other)
       loaded if @node.is_a?(Integer)
       @node == other
     end



.. _`Neo4j/ActiveRel/RelatedNode#class`:

**#class**
  

  .. code-block:: ruby

     def class
       loaded.send(:class)
     end



.. _`Neo4j/ActiveRel/RelatedNode#cypher_representation`:

**#cypher_representation**
  

  .. code-block:: ruby

     def cypher_representation(clazz)
       case
       when !set?
         "(#{formatted_label_list(clazz)})"
       when set? && !loaded?
         "(Node with neo_id #{@node})"
       else
         node_class = self.class
         id_name = node_class.id_property_name
         labels = ':' + node_class.mapped_label_names.join(':')
     
         "(#{labels} {#{id_name}: #{@node.id.inspect}})"
       end
     end



.. _`Neo4j/ActiveRel/RelatedNode#initialize`:

**#initialize**
  ActiveRel's related nodes can be initialized with nothing, an integer, or a fully wrapped node.
  
  Initialization with nothing happens when a new, non-persisted ActiveRel object is first initialized.
  
  Initialization with an integer happens when a relationship is loaded from the database. It loads using the ID
  because that is provided by the Cypher response and does not require an extra query.

  .. code-block:: ruby

     def initialize(node = nil)
       @node = valid_node_param?(node) ? node : (fail Neo4j::InvalidParameterError, 'RelatedNode must be initialized with either a node ID or node')
     end



.. _`Neo4j/ActiveRel/RelatedNode#loaded`:

**#loaded**
  Loads a node from the database or returns the node if already laoded

  .. code-block:: ruby

     def loaded
       fail UnsetRelatedNodeError, 'Node not set, cannot load' if @node.nil?
       @node = @node.respond_to?(:neo_id) ? @node : Neo4j::Node.load(@node)
     end



.. _`Neo4j/ActiveRel/RelatedNode#loaded?`:

**#loaded?**
  

  .. code-block:: ruby

     def loaded?
       @node.respond_to?(:neo_id)
     end



.. _`Neo4j/ActiveRel/RelatedNode#method_missing`:

**#method_missing**
  

  .. code-block:: ruby

     def method_missing(*args, &block)
       loaded.send(*args, &block)
     end



.. _`Neo4j/ActiveRel/RelatedNode#neo_id`:

**#neo_id**
  Returns the neo_id of a given node without loading.

  .. code-block:: ruby

     def neo_id
       loaded? ? @node.neo_id : @node
     end



.. _`Neo4j/ActiveRel/RelatedNode#respond_to_missing?`:

**#respond_to_missing?**
  

  .. code-block:: ruby

     def respond_to_missing?(method_name, include_private = false)
       loaded if @node.is_a?(Numeric)
       @node.respond_to?(method_name) ? true : super
     end



.. _`Neo4j/ActiveRel/RelatedNode#set?`:

**#set?**
  

  .. code-block:: ruby

     def set?
       !@node.nil?
     end





