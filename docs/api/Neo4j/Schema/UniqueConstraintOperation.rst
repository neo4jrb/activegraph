UniqueConstraintOperation
=========================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/schema/operation.rb:68 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/schema/operation.rb#L68>`_





Methods
-------



.. _`Neo4j/Schema/UniqueConstraintOperation#create!`:

**#create!**
  

  .. code-block:: ruby

     def create!
       return if exist?
       super
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#default_options`:

**#default_options**
  

  .. code-block:: ruby

     def default_options
       {type: :unique}
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#drop!`:

**#drop!**
  

  .. code-block:: ruby

     def drop!
       label_object.send(:"drop_#{type}", property, options)
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#drop_incompatible!`:

**#drop_incompatible!**
  

  .. code-block:: ruby

     def drop_incompatible!
       incompatible_operation_classes.each do |clazz|
         operation = clazz.new(label_name, property)
         operation.drop! if operation.exist?
       end
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#exist?`:

**#exist?**
  

  .. code-block:: ruby

     def exist?
       Neo4j::Label.constraint?(label_name, property)
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#incompatible_operation_classes`:

**#incompatible_operation_classes**
  

  .. code-block:: ruby

     def incompatible_operation_classes
       self.class.incompatible_operation_classes
     end



.. _`Neo4j/Schema/UniqueConstraintOperation.incompatible_operation_classes`:

**.incompatible_operation_classes**
  

  .. code-block:: ruby

     def self.incompatible_operation_classes
       [ExactIndexOperation]
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(label_name, property, options = default_options)
       @label_name = label_name.to_sym
       @property = property.to_sym
       @options = options
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#label_name`:

**#label_name**
  Returns the value of attribute label_name

  .. code-block:: ruby

     def label_name
       @label_name
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#label_object`:

**#label_object**
  

  .. code-block:: ruby

     def label_object
       @label_object ||= Neo4j::Label.create(label_name)
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#options`:

**#options**
  Returns the value of attribute options

  .. code-block:: ruby

     def options
       @options
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#property`:

**#property**
  Returns the value of attribute property

  .. code-block:: ruby

     def property
       @property
     end



.. _`Neo4j/Schema/UniqueConstraintOperation#type`:

**#type**
  

  .. code-block:: ruby

     def type
       'constraint'
     end





