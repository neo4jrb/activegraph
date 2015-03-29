Callbacks
=========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   Callbacks/ClassMethods

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/shared/callbacks.rb:3





Methods
-------


**#create_model**
  :nodoc:

  .. hidden-code-block:: ruby

     def create_model #:nodoc:
       Neo4j::Transaction.run do
         run_callbacks(:create) { super }
       end
     end


**#create_or_update**
  :nodoc:

  .. hidden-code-block:: ruby

     def create_or_update #:nodoc:
       run_callbacks(:save) { super }
     end


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


**#touch**
  :nodoc:

  .. hidden-code-block:: ruby

     def touch(*) #:nodoc:
       run_callbacks(:touch) { super }
     end


**#update_model**
  :nodoc:

  .. hidden-code-block:: ruby

     def update_model(*) #:nodoc:
       Neo4j::Transaction.run do
         run_callbacks(:update) { super }
       end
     end





