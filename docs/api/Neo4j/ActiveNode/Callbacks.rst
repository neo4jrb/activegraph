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



.. _`Neo4j/ActiveNode/Callbacks#conditional_callback`:

**#conditional_callback**
  Allows you to perform a callback if a condition is not satisfied.

  .. code-block:: ruby

     def conditional_callback(kind, guard)
       return yield if guard
       run_callbacks(kind) { yield }
     end



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



.. _`Neo4j/ActiveNode/Callbacks#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(args = nil)
       run_callbacks(:initialize) { super }
     end



.. _`Neo4j/ActiveNode/Callbacks#touch`:

**#touch**
  :nodoc:

  .. code-block:: ruby

     def touch #:nodoc:
       run_callbacks(:touch) { super }
     end





