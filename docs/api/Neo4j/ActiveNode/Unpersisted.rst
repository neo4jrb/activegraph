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



.. _`Neo4j/ActiveNode/Unpersisted#clear_deferred_nodes_for_association`:

**#clear_deferred_nodes_for_association**
  

  .. code-block:: ruby

     def clear_deferred_nodes_for_association(association_name)
       deferred_nodes_for_association(association_name.to_sym).clear
     end



.. _`Neo4j/ActiveNode/Unpersisted#defer_create`:

**#defer_create**
  

  .. code-block:: ruby

     def defer_create(association_name, object, options = {})
       clear_deferred_nodes_for_association(association_name) if options[:clear]
     
       deferred_nodes_for_association(association_name) << object
     end



.. _`Neo4j/ActiveNode/Unpersisted#deferred_create_cache`:

**#deferred_create_cache**
  The values in this Hash are returned and used outside by reference
  so any modifications to the Array should be in-place

  .. code-block:: ruby

     def deferred_create_cache
       @deferred_create_cache ||= {}
     end



.. _`Neo4j/ActiveNode/Unpersisted#deferred_nodes_for_association`:

**#deferred_nodes_for_association**
  

  .. code-block:: ruby

     def deferred_nodes_for_association(association_name)
       deferred_create_cache[association_name.to_sym] ||= []
     end



.. _`Neo4j/ActiveNode/Unpersisted#pending_deferred_creations?`:

**#pending_deferred_creations?**
  

  .. code-block:: ruby

     def pending_deferred_creations?
       !deferred_create_cache.values.all?(&:empty?)
     end





