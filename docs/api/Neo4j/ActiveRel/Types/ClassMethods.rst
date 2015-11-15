ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/types.rb:24 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/types.rb#L24>`_





Methods
-------



.. _`Neo4j/ActiveRel/Types/ClassMethods#_type`:

**#_type**
  When called without arguments, it will return the current setting or supply a default.
  When called with arguments, it will change the current setting.
  should be deprecated

  .. code-block:: ruby

     def type(given_type = nil, auto = false)
       case
       when !given_type && rel_type?
         @rel_type
       when given_type
         assign_type!(given_type, auto)
       else
         assign_type!(namespaced_model_name, true)
       end
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#_wrapped_classes`:

**#_wrapped_classes**
  

  .. code-block:: ruby

     def _wrapped_classes
       WRAPPED_CLASSES
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#add_wrapped_class`:

**#add_wrapped_class**
  

  .. code-block:: ruby

     def add_wrapped_class(type)
       # WRAPPED_CLASSES[type.to_sym.downcase] = self.name
       _wrapped_classes[type.to_sym] = self.name
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#decorated_rel_type`:

**#decorated_rel_type**
  

  .. code-block:: ruby

     def decorated_rel_type(type)
       @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#inherited`:

**#inherited**
  

  .. code-block:: ruby

     def inherited(subclass)
       subclass.type subclass.namespaced_model_name, true
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#namespaced_model_name`:

**#namespaced_model_name**
  

  .. code-block:: ruby

     def namespaced_model_name
       case Neo4j::Config[:module_handling]
       when :demodulize
         self.name.demodulize
       when Proc
         Neo4j::Config[:module_handling].call(self.name)
       else
         self.name
       end
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#rel_type`:

**#rel_type**
  When called without arguments, it will return the current setting or supply a default.
  When called with arguments, it will change the current setting.

  .. code-block:: ruby

     def type(given_type = nil, auto = false)
       case
       when !given_type && rel_type?
         @rel_type
       when given_type
         assign_type!(given_type, auto)
       else
         assign_type!(namespaced_model_name, true)
       end
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#rel_type?`:

**#rel_type?**
  

  .. code-block:: ruby

     def rel_type?
       !!@rel_type
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#type`:

**#type**
  When called without arguments, it will return the current setting or supply a default.
  When called with arguments, it will change the current setting.

  .. code-block:: ruby

     def type(given_type = nil, auto = false)
       case
       when !given_type && rel_type?
         @rel_type
       when given_type
         assign_type!(given_type, auto)
       else
         assign_type!(namespaced_model_name, true)
       end
     end





