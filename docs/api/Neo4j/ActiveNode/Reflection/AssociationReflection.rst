AssociationReflection
=====================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_node/reflection.rb:39





Methods
-------


**#association**
  The association object referenced by this reflection

  .. hidden-code-block:: ruby

     def association
       @association
     end


**#class_name**
  Returns the name of the target model

  .. hidden-code-block:: ruby

     def class_name
       @class_name ||= association.target_class.name
     end


**#collection?**
  

  .. hidden-code-block:: ruby

     def collection?
       macro == :has_many
     end


**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(macro, name, association)
       @macro        = macro
       @name         = name
       @association  = association
     end


**#klass**
  Returns the target model

  .. hidden-code-block:: ruby

     def klass
       @klass ||= class_name.constantize
     end


**#macro**
  The type of association

  .. hidden-code-block:: ruby

     def macro
       @macro
     end


**#name**
  The name of the association

  .. hidden-code-block:: ruby

     def name
       @name
     end


**#rel_class_name**
  

  .. hidden-code-block:: ruby

     def rel_class_name
       @rel_class_name ||= association.relationship_class.name.to_s
     end


**#rel_klass**
  

  .. hidden-code-block:: ruby

     def rel_klass
       @rel_klass ||= rel_class_name.constantize
     end


**#type**
  

  .. hidden-code-block:: ruby

     def type
       @type ||= association.relationship_type
     end


**#validate?**
  

  .. hidden-code-block:: ruby

     def validate?
       true
     end





