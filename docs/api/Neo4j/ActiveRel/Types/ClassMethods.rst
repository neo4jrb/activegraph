ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/types.rb:27 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/types.rb#L27>`_





Methods
-------


.. _ClassMethods__type:

**#_type**
  Should be deprecated

  .. hidden-code-block:: ruby

     def rel_type
       @rel_type
     end


.. _ClassMethods__wrapped_classes:

**#_wrapped_classes**
  

  .. hidden-code-block:: ruby

     def _wrapped_classes
       Neo4j::ActiveRel::Types::WRAPPED_CLASSES
     end


.. _ClassMethods_add_wrapped_class:

**#add_wrapped_class**
  

  .. hidden-code-block:: ruby

     def add_wrapped_class(type)
       # _wrapped_classes[type.to_sym.downcase] = self.name
       _wrapped_classes[type.to_sym] = self.name
     end


.. _ClassMethods_decorated_rel_type:

**#decorated_rel_type**
  

  .. hidden-code-block:: ruby

     def decorated_rel_type(type)
       @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
     end


.. _ClassMethods_inherited:

**#inherited**
  

  .. hidden-code-block:: ruby

     def inherited(other)
       other.type other.name, true
     end


.. _ClassMethods_rel_type:

**#rel_type**
  

  .. hidden-code-block:: ruby

     def rel_type
       @rel_type
     end


.. _ClassMethods_type:

**#type**
  

  .. hidden-code-block:: ruby

     def type(given_type = self.name, auto = false)
       @rel_type = (auto ? decorated_rel_type(given_type) : given_type).tap do |type|
         add_wrapped_class type unless uses_classname?
       end
     end





