ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_rel/types.rb:27





Methods
-------


**#_type**
  Should be deprecated

  .. hidden-code-block:: ruby

     def rel_type
       @rel_type
     end


**#_wrapped_classes**
  

  .. hidden-code-block:: ruby

     def _wrapped_classes
       Neo4j::ActiveRel::Types::WRAPPED_CLASSES
     end


**#add_wrapped_class**
  

  .. hidden-code-block:: ruby

     def add_wrapped_class(type)
       # _wrapped_classes[type.to_sym.downcase] = self.name
       _wrapped_classes[type.to_sym] = self.name
     end


**#decorated_rel_type**
  

  .. hidden-code-block:: ruby

     def decorated_rel_type(type)
       @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
     end


**#inherited**
  

  .. hidden-code-block:: ruby

     def inherited(other)
       other.type other.name, true
     end


**#rel_type**
  

  .. hidden-code-block:: ruby

     def rel_type
       @rel_type
     end


**#type**
  

  .. hidden-code-block:: ruby

     def type(given_type = self.name, auto = false)
       @rel_type = (auto ? decorated_rel_type(given_type) : given_type).tap do |type|
         add_wrapped_class type unless uses_classname?
       end
     end





