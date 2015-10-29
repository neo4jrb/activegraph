Unpersisted
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/unpersisted.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/unpersisted.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/Unpersisted#pending_associations`:

**#pending_associations**
  

  .. code-block:: ruby

     def pending_associations
       @pending_associations ||= {}
     end



.. _`Neo4j/ActiveNode/Unpersisted#pending_associations?`:

**#pending_associations?**
  

  .. code-block:: ruby

     def pending_associations?
       !@pending_associations.blank?
     end





