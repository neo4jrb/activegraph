Rels
====




.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * lib/neo4j/active_node/rels.rb:2





Methods
-------


**#_rels_delegator**
  

  .. hidden-code-block:: ruby

     def _rels_delegator
       fail "Can't access relationship on a non persisted node" unless _persisted_obj
       _persisted_obj
     end





