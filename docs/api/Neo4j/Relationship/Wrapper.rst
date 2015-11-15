Wrapper
=======






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/rel_wrapper.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/rel_wrapper.rb#L2>`_





Methods
-------



.. _`Neo4j/Relationship/Wrapper#wrapper`:

**#wrapper**
  

  .. code-block:: ruby

     def wrapper
       props.symbolize_keys!
       begin
         most_concrete_class = class_from_type
         wrapped_rel = most_concrete_class.constantize.new
       rescue NameError
         return self
       end
     
       wrapped_rel.init_on_load(self, self._start_node_id, self._end_node_id, self.rel_type)
       wrapped_rel
     end





