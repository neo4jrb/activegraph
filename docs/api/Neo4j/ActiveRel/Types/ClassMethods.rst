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



.. _`Neo4j/ActiveRel/Types/ClassMethods#_type`:

**#_type**
  

  .. hidden-code-block:: ruby

     def rel_type
       @rel_type || type(namespaced_model_name, true)
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#_wrapped_classes`:

**#_wrapped_classes**
  

  .. hidden-code-block:: ruby

     def _wrapped_classes
       Neo4j::ActiveRel::Types::WRAPPED_CLASSES
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#add_wrapped_class`:

**#add_wrapped_class**
  

  .. hidden-code-block:: ruby

     def add_wrapped_class(type)
       # _wrapped_classes[type.to_sym.downcase] = self.name
       _wrapped_classes[type.to_sym] = self.name
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#decorated_rel_type`:

**#decorated_rel_type**
  

  .. hidden-code-block:: ruby

     def decorated_rel_type(type)
       @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#inherited`:

**#inherited**
  

  .. hidden-code-block:: ruby

     def inherited(subclass)
       subclass.type subclass.namespaced_model_name, true
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#namespaced_model_name`:

**#namespaced_model_name**
  

  .. hidden-code-block:: ruby

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
  

  .. hidden-code-block:: ruby

     def rel_type
       @rel_type || type(namespaced_model_name, true)
     end



.. _`Neo4j/ActiveRel/Types/ClassMethods#type`:

**#type**
  This option is used internally, users will usually ignore it.

  .. hidden-code-block:: ruby

     def type(given_type = nil, auto = false)
       return rel_type if given_type.nil?
       @rel_type = (auto ? decorated_rel_type(given_type) : given_type).tap do |type|
         add_wrapped_class(type) unless uses_classname?
       end
     end





