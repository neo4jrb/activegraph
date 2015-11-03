ClassMethods
============



Adds methods to the class related to creating and retrieving reflections.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/reflection.rb:14 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/reflection.rb#L14>`_





Methods
-------



.. _`Neo4j/ActiveNode/Reflection/ClassMethods#reflect_on_all_associations`:

**#reflect_on_all_associations**
  Returns an array containing one reflection for each association declared in the model.

  .. code-block:: ruby

     def reflect_on_all_associations(macro = nil)
       association_reflections = reflections.values
       macro ? association_reflections.select { |reflection| reflection.macro == macro } : association_reflections
     end



.. _`Neo4j/ActiveNode/Reflection/ClassMethods#reflect_on_association`:

**#reflect_on_association**
  

  .. code-block:: ruby

     def reflect_on_association(association)
       reflections[association.to_sym]
     end





