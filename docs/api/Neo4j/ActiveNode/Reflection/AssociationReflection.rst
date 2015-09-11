AssociationReflection
=====================



The actual reflection object that contains information about the given association.
These should never need to be created manually, they will always be created by declaring a :has_many or :has_one association on a model.


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



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#association`:

**#association**
  The association object referenced by this reflection

  .. code-block:: ruby

     def association
       @association
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#class_name`:

**#class_name**
  Returns the name of the target model

  .. code-block:: ruby

     def class_name
       @class_name ||= association.target_class.name
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#collection?`:

**#collection?**
  

  .. code-block:: ruby

     def collection?
       macro == :has_many
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(macro, name, association)
       @macro        = macro
       @name         = name
       @association  = association
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#klass`:

**#klass**
  Returns the target model

  .. code-block:: ruby

     def klass
       @klass ||= class_name.constantize
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#macro`:

**#macro**
  The type of association

  .. code-block:: ruby

     def macro
       @macro
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#name`:

**#name**
  The name of the association

  .. code-block:: ruby

     def name
       @name
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#rel_class_name`:

**#rel_class_name**
  

  .. code-block:: ruby

     def rel_class_name
       @rel_class_name ||= association.relationship_class.name.to_s
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#rel_klass`:

**#rel_klass**
  

  .. code-block:: ruby

     def rel_klass
       @rel_klass ||= rel_class_name.constantize
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#type`:

**#type**
  

  .. code-block:: ruby

     def type
       @type ||= association.relationship_type
     end



.. _`Neo4j/ActiveNode/Reflection/AssociationReflection#validate?`:

**#validate?**
  

  .. code-block:: ruby

     def validate?
       true
     end





