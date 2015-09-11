ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/persistence.rb:232 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/persistence.rb#L232>`_





Methods
-------



.. _`Neo4j/Shared/Persistence/ClassMethods#cached_class?`:

**#cached_class?**
  Determines whether a model should insert a _classname property. This can be used to override the automatic matching of returned
  objects to models.

  .. code-block:: ruby

     def cached_class?(check_version = true)
       uses_classname? || (!!Neo4j::Config[:cache_class_names] && (check_version ? neo4j_session.version < '2.1.5' : true))
     end



.. _`Neo4j/Shared/Persistence/ClassMethods#set_classname`:

**#set_classname**
  Adds this model to the USES_CLASSNAME array. When new rels/nodes are created, a _classname property will be added. This will override the
  automatic matching of label/rel type to model.
  
  You'd want to do this if you have multiple models for the same label or relationship type. When it comes to labels, there isn't really any
  reason to do this because you can have multiple labels; on the other hand, an argument can be made for doing this with relationships since
  rel type is a bit more restrictive.
  
  It could also be speculated that there's a slight performance boost to using _classname since the gem immediately knows what model is responsible
  for a returned object. At the same time, it is a bit restrictive and changing it can be a bit of a PITA. Use carefully!

  .. code-block:: ruby

     def set_classname
       Neo4j::Shared::Persistence::USES_CLASSNAME << self.name
     end



.. _`Neo4j/Shared/Persistence/ClassMethods#unset_classname`:

**#unset_classname**
  Removes this model from the USES_CLASSNAME array. When new rels/nodes are create, no _classname property will be injected. Upon returning of
  the object from the database, it will be matched to a model using its relationship type or labels.

  .. code-block:: ruby

     def unset_classname
       Neo4j::Shared::Persistence::USES_CLASSNAME.delete self.name
     end



.. _`Neo4j/Shared/Persistence/ClassMethods#uses_classname?`:

**#uses_classname?**
  

  .. code-block:: ruby

     def uses_classname?
       Neo4j::Shared::Persistence::USES_CLASSNAME.include?(self.name)
     end





