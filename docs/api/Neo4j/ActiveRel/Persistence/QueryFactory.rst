QueryFactory
============



This class builds and executes a Cypher query, using information from the graph objects to determine
  whether they need to be created simultaneously.
  It keeps the rel instance from being responsible for inspecting the nodes or talking with Shared::QueryFactory.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * NODE_SYMBOLS



Files
-----



  * `lib/neo4j/active_rel/persistence/query_factory.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/persistence/query_factory.rb#L5>`_





Methods
-------



.. _`Neo4j/ActiveRel/Persistence/QueryFactory#build!`:

**#build!**
  TODO: This feels like it should also wrap the rel, but that is handled in Neo4j::ActiveRel::Persistence at the moment.
  Builds and executes the query using the objects giving during init.
  It holds the process:
    * Execute node callbacks if needed
    * Create and execute the query
    * Mix the query response into the unpersisted objects given during init

  .. code-block:: ruby

     def build!
       node_before_callbacks! do
         res = query_factory(rel, rel_id, iterative_query).query.unwrapped.return(*unpersisted_return_ids).first
         node_symbols.each { |n| wrap!(send(n), res, n) }
         @unwrapped_rel = res.send(rel_id)
       end
     end



.. _`Neo4j/ActiveRel/Persistence/QueryFactory#from_node`:

**#from_node**
  Returns the value of attribute from_node

  .. code-block:: ruby

     def from_node
       @from_node
     end



.. _`Neo4j/ActiveRel/Persistence/QueryFactory#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(from_node, to_node, rel)
       @from_node = from_node
       @to_node = to_node
       @rel = rel
     end



.. _`Neo4j/ActiveRel/Persistence/QueryFactory#rel`:

**#rel**
  Returns the value of attribute rel

  .. code-block:: ruby

     def rel
       @rel
     end



.. _`Neo4j/ActiveRel/Persistence/QueryFactory#to_node`:

**#to_node**
  Returns the value of attribute to_node

  .. code-block:: ruby

     def to_node
       @to_node
     end



.. _`Neo4j/ActiveRel/Persistence/QueryFactory#unwrapped_rel`:

**#unwrapped_rel**
  Returns the value of attribute unwrapped_rel

  .. code-block:: ruby

     def unwrapped_rel
       @unwrapped_rel
     end





