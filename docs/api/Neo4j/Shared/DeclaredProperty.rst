DeclaredProperty
================



Contains methods related to the management


.. toctree::
   :maxdepth: 3
   :titlesonly:


   DeclaredProperty/IllegalPropertyError

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   DeclaredProperty/Index




Constants
---------



  * ILLEGAL_PROPS



Files
-----



  * `lib/neo4j/shared/declared_property.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/declared_property.rb#L3>`_

  * `lib/neo4j/shared/declared_property/index.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/declared_property/index.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/DeclaredProperty#<=>`:

**#<=>**
  Compare attribute definitions

  .. code-block:: ruby

     def <=>(other)
       return nil unless other.instance_of? self.class
       return nil if name == other.name && options != other.options
       self.to_s <=> other.to_s
     end



.. _`Neo4j/Shared/DeclaredProperty#[]`:

**#[]**
  

  .. code-block:: ruby

     def [](key)
       respond_to?(key) ? public_send(key) : nil
     end



.. _`Neo4j/Shared/DeclaredProperty#constraint!`:

**#constraint!**
  

  .. code-block:: ruby

     def constraint!(type = :unique)
       fail Neo4j::InvalidPropertyOptionsError, "Unable to set constraint on indexed property #{name}" if index?(:exact)
       options[:constraint] = type
     end



.. _`Neo4j/Shared/DeclaredProperty#constraint?`:

**#constraint?**
  

  .. code-block:: ruby

     def constraint?(type = :unique)
       options.key?(:constraint) && options[:constraint] == type
     end



.. _`Neo4j/Shared/DeclaredProperty#default`:

**#default**
  

  .. code-block:: ruby

     def default_value
       options[:default]
     end



.. _`Neo4j/Shared/DeclaredProperty#default_value`:

**#default_value**
  

  .. code-block:: ruby

     def default_value
       options[:default]
     end



.. _`Neo4j/Shared/DeclaredProperty#fail_invalid_options!`:

**#fail_invalid_options!**
  

  .. code-block:: ruby

     def fail_invalid_options!
       case
       when index?(:exact) && constraint?(:unique)
         fail Neo4j::InvalidPropertyOptionsError,
              "#Uniqueness constraints also provide exact indexes, cannot set both options on property #{name}"
       end
     end



.. _`Neo4j/Shared/DeclaredProperty#index!`:

**#index!**
  

  .. code-block:: ruby

     def index!(type = :exact)
       fail Neo4j::InvalidPropertyOptionsError, "Unable to set index on constrainted property #{name}" if constraint?(:unique)
       options[:index] = type
     end



.. _`Neo4j/Shared/DeclaredProperty#index?`:

**#index?**
  

  .. code-block:: ruby

     def index?(type = :exact)
       options.key?(:index) && options[:index] == type
     end



.. _`Neo4j/Shared/DeclaredProperty#index_or_constraint?`:

**#index_or_constraint?**
  

  .. code-block:: ruby

     def index_or_constraint?
       index?(:exact) || constraint?(:unique)
     end



.. _`Neo4j/Shared/DeclaredProperty#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(name, options = {})
       fail IllegalPropertyError, "#{name} is an illegal property" if ILLEGAL_PROPS.include?(name.to_s)
       fail TypeError, "can't convert #{name.class} into Symbol" unless name.respond_to?(:to_sym)
       @name = @name_sym = name.to_sym
       @name_string = name.to_s
       @options = options
       fail_invalid_options!
     end



.. _`Neo4j/Shared/DeclaredProperty#inspect`:

**#inspect**
  

  .. code-block:: ruby

     def inspect
       options_description = options.map { |key, value| "#{key.inspect} => #{value.inspect}" }.sort.join(', ')
       inspected_options = ", #{options_description}" unless options_description.empty?
       "attribute :#{name}#{inspected_options}"
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



.. _`Neo4j/Shared/DeclaredProperty#to_s`:

**#to_s**
  

  .. code-block:: ruby

     def to_s
       name.to_s
     end



.. _`Neo4j/Shared/DeclaredProperty#to_sym`:

**#to_sym**
  

  .. code-block:: ruby

     def to_sym
       name
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



.. _`Neo4j/Shared/DeclaredProperty#unconstraint!`:

**#unconstraint!**
  

  .. code-block:: ruby

     def unconstraint!(type = :unique)
       options.delete(:constraint) if constraint?(type)
     end



.. _`Neo4j/Shared/DeclaredProperty#unindex!`:

**#unindex!**
  

  .. code-block:: ruby

     def unindex!(type = :exact)
       options.delete(:index) if index?(type)
     end





