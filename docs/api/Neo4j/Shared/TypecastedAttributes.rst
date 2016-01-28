TypecastedAttributes
====================



TypecastedAttributes allows types to be declared for your attributes

Types are declared by passing the :type option to the attribute class
method. After a type is declared, attribute readers will convert any
assigned attribute value to the declared type. If the assigned value
cannot be cast, nil will be returned instead. You can access the original
assigned value using the before_type_cast methods.

See {Typecasting} for the currently supported types.

Originally part of ActiveAttr, https://github.com/cgriego/active_attr


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   TypecastedAttributes/ClassMethods




Constants
---------



  * DEPRECATED_OBJECT_METHODS



Files
-----



  * `lib/neo4j/shared/typecasted_attributes.rb:24 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/typecasted_attributes.rb#L24>`_





Methods
-------



.. _`Neo4j/Shared/TypecastedAttributes#==`:

**#==**
  Performs equality checking on the result of attributes and its type.

  .. code-block:: ruby

     def ==(other)
       return false unless other.instance_of? self.class
       attributes == other.attributes
     end



.. _`Neo4j/Shared/TypecastedAttributes#[]=`:

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



.. _`Neo4j/Shared/TypecastedAttributes#attribute_before_type_cast`:

**#attribute_before_type_cast**
  Read the raw attribute value

  .. code-block:: ruby

     def attribute_before_type_cast(name)
       @attributes ||= {}
       @attributes[name.to_s]
     end



.. _`Neo4j/Shared/TypecastedAttributes#attributes`:

**#attributes**
  Returns a Hash of all attributes

  .. code-block:: ruby

     def attributes
       attributes_map { |name| send name }
     end



.. _`Neo4j/Shared/TypecastedAttributes#write_attribute`:

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





