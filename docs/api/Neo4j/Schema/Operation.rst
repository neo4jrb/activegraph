Operation
=========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/schema/operation.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/schema/operation.rb#L3>`_





Methods
-------



.. _`Neo4j/Schema/Operation#create!`:

**#create!**
  

  .. code-block:: ruby

     def create!
       drop_incompatible!
       return if exist?
       label_object.send(:"create_#{type}", property, options)
     end



.. _`Neo4j/Schema/Operation#default_options`:

**#default_options**
  

  .. code-block:: ruby

     def default_options
       {}
     end



.. _`Neo4j/Schema/Operation#drop!`:

**#drop!**
  

  .. code-block:: ruby

     def drop!
       label_object.send(:"drop_#{type}", property, options)
     end



.. _`Neo4j/Schema/Operation#drop_incompatible!`:

**#drop_incompatible!**
  

  .. code-block:: ruby

     def drop_incompatible!
       incompatible_operation_classes.each do |clazz|
         operation = clazz.new(label_name, property)
         operation.drop! if operation.exist?
       end
     end



.. _`Neo4j/Schema/Operation#exist?`:

**#exist?**
  

  .. code-block:: ruby

     def exist?
       fail 'Abstract class, not implemented'
     end



.. _`Neo4j/Schema/Operation#incompatible_operation_classes`:

**#incompatible_operation_classes**
  

  .. code-block:: ruby

     def incompatible_operation_classes
       self.class.incompatible_operation_classes
     end



.. _`Neo4j/Schema/Operation.incompatible_operation_classes`:

**.incompatible_operation_classes**
  

  .. code-block:: ruby

     def self.incompatible_operation_classes
       []
     end



.. _`Neo4j/Schema/Operation#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(label_name, property, options = default_options)
       @label_name = label_name.to_sym
       @property = property.to_sym
       @options = options
     end



.. _`Neo4j/Schema/Operation#label_name`:

**#label_name**
  Returns the value of attribute label_name

  .. code-block:: ruby

     def label_name
       @label_name
     end



.. _`Neo4j/Schema/Operation#label_object`:

**#label_object**
  

  .. code-block:: ruby

     def label_object
       @label_object ||= Neo4j::Label.create(label_name)
     end



.. _`Neo4j/Schema/Operation#options`:

**#options**
  Returns the value of attribute options

  .. code-block:: ruby

     def options
       @options
     end



.. _`Neo4j/Schema/Operation#property`:

**#property**
  Returns the value of attribute property

  .. code-block:: ruby

     def property
       @property
     end



.. _`Neo4j/Schema/Operation#type`:

**#type**
  

  .. code-block:: ruby

     def type
       fail 'Abstract class, not implemented'
     end





