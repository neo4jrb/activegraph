Property
========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   Property/UndefinedPropertyError

   Property/MultiparameterAssignmentError

   Property/IllegalPropertyError

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   Property/ClassMethods




Constants
---------



  * ILLEGAL_PROPS



Files
-----



  * `lib/neo4j/shared/property.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/property.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/Property#[]`:

**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/Shared/Property#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/Shared/Property#default_properties`:

**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
       # keys = self.class.default_properties.keys
       # _persisted_obj.props.reject{|key| !keys.include?(key)}
     end



.. _`Neo4j/Shared/Property#default_properties=`:

**#default_properties=**
  

  .. hidden-code-block:: ruby

     def default_properties=(properties)
       default_property_keys = self.class.default_properties_keys
       @default_properties = properties.select { |key| default_property_keys.include?(key) }
     end



.. _`Neo4j/Shared/Property#default_property`:

**#default_property**
  

  .. hidden-code-block:: ruby

     def default_property(key)
       default_properties[key.to_sym]
     end



.. _`Neo4j/Shared/Property#initialize`:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(attributes = {}, options = {})
       attributes = process_attributes(attributes) unless attributes.empty?
       @relationship_props = self.class.extract_association_attributes!(attributes)
       writer_method_props = extract_writer_methods!(attributes)
       validate_attributes!(attributes)
       send_props(writer_method_props) unless writer_method_props.empty?
     
       @_persisted_obj = nil
     
       super(attributes, options)
     end



.. _`Neo4j/Shared/Property#read_attribute`:

**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/Shared/Property#send_props`:

**#send_props**
  

  .. hidden-code-block:: ruby

     def send_props(hash)
       hash.each { |key, value| self.send("#{key}=", value) }
     end





