Property
========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   Property/UndefinedPropertyError

   Property/MultiparameterAssignmentError

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   Property/ClassMethods




Constants
---------



  * DATE_KEY_REGEX



Files
-----



  * `lib/neo4j/shared/property.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/property.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/Property#[]`:

**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/Shared/Property#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/Shared/Property#initialize`:

**#initialize**
  TODO: Remove the commented :super entirely once this code is part of a release.
  It calls an init method in active_attr that has a very negative impact on performance.

  .. code-block:: ruby

     def initialize(attributes = nil)
       attributes = process_attributes(attributes)
       @relationship_props = self.class.extract_association_attributes!(attributes)
       modded_attributes = inject_defaults!(attributes)
       validate_attributes!(modded_attributes)
       writer_method_props = extract_writer_methods!(modded_attributes)
       send_props(writer_method_props)
       @_persisted_obj = nil
     end



.. _`Neo4j/Shared/Property#inject_defaults!`:

**#inject_defaults!**
  

  .. code-block:: ruby

     def inject_defaults!(starting_props)
       return starting_props if self.class.declared_properties.declared_property_defaults.empty?
       self.class.declared_properties.inject_defaults!(self, starting_props || {})
     end



.. _`Neo4j/Shared/Property#inspect`:

**#inspect**
  

  .. code-block:: ruby

     def inspect
       attribute_descriptions = inspect_attributes.map do |key, value|
         "#{Neo4j::ANSI::CYAN}#{key}: #{Neo4j::ANSI::CLEAR}#{value.inspect}"
       end.join(', ')
     
       separator = ' ' unless attribute_descriptions.empty?
       "#<#{Neo4j::ANSI::YELLOW}#{self.class.name}#{Neo4j::ANSI::CLEAR}#{separator}#{attribute_descriptions}>"
     end



.. _`Neo4j/Shared/Property#read_attribute`:

**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/Shared/Property#send_props`:

**#send_props**
  

  .. code-block:: ruby

     def send_props(hash)
       return hash if hash.blank?
       hash.each { |key, value| send("#{key}=", value) }
     end





