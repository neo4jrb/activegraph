Wrapper
=======




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_rel/rel_wrapper.rb:2





Methods
-------


**#class_from_type**
  

  .. hidden-code-block:: ruby

     def class_from_type
       Neo4j::ActiveRel::Types::WRAPPED_CLASSES[rel_type] || rel_type.camelize
     end


**#sorted_wrapper_classes**
  

  .. hidden-code-block:: ruby

     def sorted_wrapper_classes
       props[Neo4j::Config.class_name_property] || class_from_type
     end


**#wrapper**
  

  .. hidden-code-block:: ruby

     def wrapper
       props.symbolize_keys!
       # return self unless props.is_a?(Hash)
       begin
         most_concrete_class = sorted_wrapper_classes
         wrapped_rel = most_concrete_class.constantize.new
       rescue NameError
         return self
       end
     
       wrapped_rel.init_on_load(self, self._start_node_id, self._end_node_id, self.rel_type)
       wrapped_rel
     end





