RelatedNode
===========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   RelatedNode/InvalidParameterError

   

   

   

   

   

   

   

   




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

  .. hidden-code-block:: ruby

     def ==(other)
       loaded if @node.is_a?(Integer)
       @node == other
     end



.. _`Neo4j/ActiveRel/RelatedNode#class`:

**#class**
  

  .. hidden-code-block:: ruby

     def class
       loaded.send(:class)
     end



.. _`Neo4j/ActiveRel/RelatedNode#initialize`:

**#initialize**
  ActiveRel's related nodes can be initialized with nothing, an integer, or a fully wrapped node.
  
  Initialization with nothing happens when a new, non-persisted ActiveRel object is first initialized.
  
  Initialization with an integer happens when a relationship is loaded from the database. It loads using the ID
  because that is provided by the Cypher response and does not require an extra query.
  
  Initialization with a node doesn't appear to happen in the code. TODO: maybe find out why this is an option.

  .. hidden-code-block:: ruby

     def initialize(node = nil)
       @node = valid_node_param?(node) ? node : (fail InvalidParameterError, 'RelatedNode must be initialized with either a node ID or node')
     end



.. _`Neo4j/ActiveRel/RelatedNode#loaded`:

**#loaded**
  Loads a node from the database or returns the node if already laoded

  .. hidden-code-block:: ruby

     def loaded
       @node = @node.respond_to?(:neo_id) ? @node : Neo4j::Node.load(@node)
     end



.. _`Neo4j/ActiveRel/RelatedNode#loaded?`:

**#loaded?**
  

  .. hidden-code-block:: ruby

     def loaded?
       @node.respond_to?(:neo_id)
     end



.. _`Neo4j/ActiveRel/RelatedNode#method_missing`:

**#method_missing**
  

  .. hidden-code-block:: ruby

     def method_missing(*args, &block)
       loaded.send(*args, &block)
     end



.. _`Neo4j/ActiveRel/RelatedNode#neo_id`:

**#neo_id**
  Returns the neo_id of a given node without loading.

  .. hidden-code-block:: ruby

     def neo_id
       loaded? ? @node.neo_id : @node
     end





