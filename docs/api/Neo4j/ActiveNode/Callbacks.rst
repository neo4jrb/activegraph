Callbacks
=========



:nodoc:


.. toctree::
   :maxdepth: 3
   :titlesonly:





Constants
---------





Files
-----



  * `lib/neo4j/active_node/callbacks.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/callbacks.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/Callbacks#destroy`:

**#destroy**
  :nodoc:

  .. code-block:: ruby

     def destroy #:nodoc:
       tx = Neo4j::Transaction.new
       run_callbacks(:destroy) { super }
     rescue
       @_deleted = false
       @attributes = @attributes.dup
       tx.mark_failed
       raise
     ensure
       tx.close if tx
     end



.. _`Neo4j/ActiveNode/Callbacks#touch`:

**#touch**
  :nodoc:

  .. code-block:: ruby

     def touch(*) #:nodoc:
       run_callbacks(:touch) { super }
     end





