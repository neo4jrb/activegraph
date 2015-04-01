Callbacks
=========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/callbacks.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/callbacks.rb#L3>`_





Methods
-------


.. _Callbacks_destroy:

**#destroy**
  :nodoc:

  .. hidden-code-block:: ruby

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


.. _Callbacks_save:

**#save**
  

  .. hidden-code-block:: ruby

     def save(*args)
       unless self.persisted? || (from_node.respond_to?(:neo_id) && to_node.respond_to?(:neo_id))
         fail Neo4j::ActiveRel::Persistence::RelInvalidError, 'from_node and to_node must be node objects'
       end
       super(*args)
     end


.. _Callbacks_touch:

**#touch**
  :nodoc:

  .. hidden-code-block:: ruby

     def touch(*) #:nodoc:
       run_callbacks(:touch) { super }
     end





