Initialize
==========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/initialize.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/initialize.rb#L2>`_





Methods
-------


.. _Initialize__persisted_obj:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end


.. _Initialize_convert_properties_to:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
     
       properties.each_with_object({}) do |(attr, value), new_attributes|
         next new_attributes if skip_conversion?(attr, value)
         new_attributes[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end


.. _Initialize_init_on_load:

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


.. _Initialize_wrapper:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





