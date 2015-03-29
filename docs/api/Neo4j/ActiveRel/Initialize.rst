Initialize
==========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_rel/initialize.rb:2





Methods
-------


**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end


**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
     
       properties.each_with_object({}) do |(attr, value), new_attributes|
         next new_attributes if skip_conversion?(attr, value)
         new_attributes[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end


**#converted_property**
  

  .. hidden-code-block:: ruby

     def converted_property(type, value, converter)
       TypeConverters.converters[type].nil? ? value : TypeConverters.to_other(converter, value, type)
     end


**#init_on_load**
  called when loading the rel from the database

  .. hidden-code-block:: ruby

     def init_on_load(persisted_rel, from_node_id, to_node_id, type)
       @_persisted_obj = persisted_rel
       @rel_type = type
       changed_attributes && changed_attributes.clear
       @attributes = attributes.merge(persisted_rel.props.stringify_keys)
       load_nodes(from_node_id, to_node_id)
       self.default_properties = persisted_rel.props
       @attributes = convert_properties_to :ruby, @attributes
     end


**#primitive_type**
  If the attribute is to be typecast using a custom converter, which converter should it use? If no, returns the type to find a native serializer.

  .. hidden-code-block:: ruby

     def primitive_type(attr)
       case
       when serialized_properties.key?(attr)
         serialized_properties[attr]
       when magic_typecast_properties.key?(attr)
         self.class.magic_typecast_properties[attr]
       else
         self.class._attribute_type(attr)
       end
     end


**#skip_conversion?**
  Returns true if the property isn't defined in the model or it's both nil and unchanged.

  .. hidden-code-block:: ruby

     def skip_conversion?(attr, value)
       !self.class.attributes[attr] || (value.nil? && !changed_attributes.key?(attr))
     end


**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





