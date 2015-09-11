DeclaredProperty
================



Contains methods related to the management


.. toctree::
   :maxdepth: 3
   :titlesonly:


   DeclaredProperty/IllegalPropertyError

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * ILLEGAL_PROPS



Files
-----



  * `lib/neo4j/shared/declared_property.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/declared_property.rb#L3>`_





Methods
-------



.. _`Neo4j/Shared/DeclaredProperty#default_value`:

**#default_value**
  

  .. code-block:: ruby

     def default_value
       options[:default]
     end



.. _`Neo4j/Shared/DeclaredProperty#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(name, options = {})
       fail IllegalPropertyError, "#{name} is an illegal property" if ILLEGAL_PROPS.include?(name.to_s)
       @name = @name_sym = name
       @name_string = name.to_s
       @options = options
     end



.. _`Neo4j/Shared/DeclaredProperty#magic_typecaster`:

**#magic_typecaster**
  Returns the value of attribute magic_typecaster

  .. code-block:: ruby

     def magic_typecaster
       @magic_typecaster
     end



.. _`Neo4j/Shared/DeclaredProperty#name`:

**#name**
  Returns the value of attribute name

  .. code-block:: ruby

     def name
       @name
     end



.. _`Neo4j/Shared/DeclaredProperty#name_string`:

**#name_string**
  Returns the value of attribute name_string

  .. code-block:: ruby

     def name_string
       @name_string
     end



.. _`Neo4j/Shared/DeclaredProperty#name_sym`:

**#name_sym**
  Returns the value of attribute name_sym

  .. code-block:: ruby

     def name_sym
       @name_sym
     end



.. _`Neo4j/Shared/DeclaredProperty#options`:

**#options**
  Returns the value of attribute options

  .. code-block:: ruby

     def options
       @options
     end



.. _`Neo4j/Shared/DeclaredProperty#register`:

**#register**
  

  .. code-block:: ruby

     def register
       register_magic_properties
     end



.. _`Neo4j/Shared/DeclaredProperty#type`:

**#type**
  

  .. code-block:: ruby

     def type
       options[:type]
     end



.. _`Neo4j/Shared/DeclaredProperty#typecaster`:

**#typecaster**
  

  .. code-block:: ruby

     def typecaster
       options[:typecaster]
     end





