Attributes
==========



Attributes provides a set of class methods for defining an attributes
schema and instance methods for reading and writing attributes.

Originally part of ActiveAttr, https://github.com/cgriego/active_attr


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   Attributes/ClassMethods




Constants
---------



  * DEPRECATED_OBJECT_METHODS



Files
-----



  * `lib/neo4j/shared/attributes.rb:15 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/attributes.rb#L15>`_





Methods
-------



.. _`Neo4j/Shared/Attributes#==`:

**#==**
  Performs equality checking on the result of attributes and its type.

  .. code-block:: ruby

     def ==(other)
       return false unless other.instance_of? self.class
       attributes == other.attributes
     end



.. _`Neo4j/Shared/Attributes#[]=`:

**#[]=**
  Write a single attribute to the model's attribute hash.

  .. code-block:: ruby

     def write_attribute(name, value)
       if respond_to? "#{name}="
         send "#{name}=", value
       else
         fail Neo4j::UnknownAttributeError, "unknown attribute: #{name}"
       end
     end



.. _`Neo4j/Shared/Attributes#attributes`:

**#attributes**
  Returns a Hash of all attributes

  .. code-block:: ruby

     def attributes
       attributes_map { |name| send name }
     end



.. _`Neo4j/Shared/Attributes#write_attribute`:

**#write_attribute**
  Write a single attribute to the model's attribute hash.

  .. code-block:: ruby

     def write_attribute(name, value)
       if respond_to? "#{name}="
         send "#{name}=", value
       else
         fail Neo4j::UnknownAttributeError, "unknown attribute: #{name}"
       end
     end





