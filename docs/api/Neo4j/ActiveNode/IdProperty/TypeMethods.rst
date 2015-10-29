TypeMethods
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/id_property.rb:39 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property.rb#L39>`_





Methods
-------



.. _`Neo4j/ActiveNode/IdProperty/TypeMethods#define_id_methods`:

**#define_id_methods**
  

  .. code-block:: ruby

     def define_id_methods(clazz, name, conf)
       validate_conf!(conf)
     
       if conf[:on]
         define_custom_method(clazz, name, conf[:on])
       elsif conf[:auto]
         define_uuid_method(clazz, name)
       elsif conf.empty?
         define_property_method(clazz, name)
       end
     end



.. _`Neo4j/ActiveNode/IdProperty/TypeMethods.define_id_methods`:

**.define_id_methods**
  

  .. code-block:: ruby

     def define_id_methods(clazz, name, conf)
       validate_conf!(conf)
     
       if conf[:on]
         define_custom_method(clazz, name, conf[:on])
       elsif conf[:auto]
         define_uuid_method(clazz, name)
       elsif conf.empty?
         define_property_method(clazz, name)
       end
     end





