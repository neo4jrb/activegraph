AssociationReflection
=====================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/reflection.rb:39 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/reflection.rb#L39>`_





Methods
-------


.. _AssociationReflection_association:

**#association**
  The association object referenced by this reflection

  .. hidden-code-block:: ruby

     def association
       @association
     end


.. _AssociationReflection_class_name:

**#class_name**
  Returns the name of the target model

  .. hidden-code-block:: ruby

     def class_name
       @class_name ||= association.target_class.name
     end


.. _AssociationReflection_collection?:

**#collection?**
  

  .. hidden-code-block:: ruby

     def collection?
       macro == :has_many
     end


.. _AssociationReflection_initialize:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(macro, name, association)
       @macro        = macro
       @name         = name
       @association  = association
     end


.. _AssociationReflection_klass:

**#klass**
  Returns the target model

  .. hidden-code-block:: ruby

     def klass
       @klass ||= class_name.constantize
     end


.. _AssociationReflection_macro:

**#macro**
  The type of association

  .. hidden-code-block:: ruby

     def macro
       @macro
     end


.. _AssociationReflection_name:

**#name**
  The name of the association

  .. hidden-code-block:: ruby

     def name
       @name
     end


.. _AssociationReflection_rel_class_name:

**#rel_class_name**
  

  .. hidden-code-block:: ruby

     def rel_class_name
       @rel_class_name ||= association.relationship_class.name.to_s
     end


.. _AssociationReflection_rel_klass:

**#rel_klass**
  

  .. hidden-code-block:: ruby

     def rel_klass
       @rel_klass ||= rel_class_name.constantize
     end


.. _AssociationReflection_type:

**#type**
  

  .. hidden-code-block:: ruby

     def type
       @type ||= association.relationship_type
     end


.. _AssociationReflection_validate?:

**#validate?**
  

  .. hidden-code-block:: ruby

     def validate?
       true
     end





