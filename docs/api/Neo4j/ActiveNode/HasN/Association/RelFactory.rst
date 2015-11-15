RelFactory
==========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/has_n/association/rel_factory.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association/rel_factory.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/HasN/Association/RelFactory#_create_relationship`:

**#_create_relationship**
  

  .. code-block:: ruby

     def _create_relationship
       creator = association.relationship_class ? :rel_class : :factory
       send(:"_create_relationship_with_#{creator}")
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelFactory.create`:

**.create**
  

  .. code-block:: ruby

     def self.create(start_object, other_node_or_nodes, properties, association)
       factory = new(start_object, other_node_or_nodes, properties, association)
       factory._create_relationship
     end





