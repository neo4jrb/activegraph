Rels
====






.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/rels.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/rels.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveNode/Rels#_rels_delegator`:

**#_rels_delegator**
  

  .. code-block:: ruby

     def _rels_delegator
       fail "Can't access relationship on a non persisted node" unless _persisted_obj
       _persisted_obj
     end





