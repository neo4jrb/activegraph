ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/attributes.rb:98 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/attributes.rb#L98>`_





Methods
-------



.. _`Neo4j/Shared/Attributes/ClassMethods#attribute`:

**#attribute**
  Defines an attribute
  
  For each attribute that is defined, a getter and setter will be
  added as an instance method to the model. An
  {AttributeDefinition} instance will be added to result of the
  attributes class method.

  .. code-block:: ruby

     def attribute(name)
       if dangerous_attribute?(name)
         fail Neo4j::DangerousAttributeError, %(an attribute method named "#{name}" would conflict with an existing method)
       else
         attribute!(name)
       end
     end



.. _`Neo4j/Shared/Attributes/ClassMethods#attribute_names`:

**#attribute_names**
  Returns an Array of attribute names as Strings

  .. code-block:: ruby

     def attribute_names
       attributes.keys
     end



.. _`Neo4j/Shared/Attributes/ClassMethods#attributes`:

**#attributes**
  Returns a Hash of AttributeDefinition instances

  .. code-block:: ruby

     def attributes
       @attributes ||= ActiveSupport::HashWithIndifferentAccess.new
     end



.. _`Neo4j/Shared/Attributes/ClassMethods#dangerous_attribute?`:

**#dangerous_attribute?**
  Determine if a given attribute name is dangerous
  
  Some attribute names can cause conflicts with existing methods
  on an object. For example, an attribute named "timeout" would
  conflict with the timeout method that Ruby's Timeout library
  mixes into Object.

  .. code-block:: ruby

     def dangerous_attribute?(name)
       attribute_methods(name).detect do |method_name|
         !DEPRECATED_OBJECT_METHODS.include?(method_name.to_s) && allocate.respond_to?(method_name, true)
       end unless attribute_names.include? name.to_s
     end



.. _`Neo4j/Shared/Attributes/ClassMethods#inspect`:

**#inspect**
  Returns the class name plus its attribute names

  .. code-block:: ruby

     def inspect
       inspected_attributes = attribute_names.sort
       attributes_list = "(#{inspected_attributes.join(', ')})" unless inspected_attributes.empty?
       "#{name}#{attributes_list}"
     end





