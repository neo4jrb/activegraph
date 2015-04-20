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



.. _`Neo4j/ActiveRel/Initialize#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/ActiveRel/Initialize#convert_properties_to`:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
       properties.each_pair do |attr, value|
         next if skip_conversion?(attr, value)
         properties[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end



.. _`Neo4j/ActiveRel/Initialize#init_on_load`:

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



.. _`Neo4j/ActiveRel/Initialize#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





