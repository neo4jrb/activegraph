ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_node/reflection.rb:14





Methods
-------


**#create_reflection**
  

  .. hidden-code-block:: ruby

     def create_reflection(macro, name, association_object, model)
       self.reflections = self.reflections.merge(name => AssociationReflection.new(macro, name, association_object))
       association_object.add_destroy_callbacks(model)
     end


**#reflect_on_all_associations**
  Returns an array containing one reflection for each association declared in the model.

  .. hidden-code-block:: ruby

     def reflect_on_all_associations(macro = nil)
       association_reflections = reflections.values
       macro ? association_reflections.select { |reflection| reflection.macro == macro } : association_reflections
     end


**#reflect_on_association**
  

  .. hidden-code-block:: ruby

     def reflect_on_association(association)
       reflections[association.to_sym]
     end





