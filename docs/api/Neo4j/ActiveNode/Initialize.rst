Initialize
==========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/initialize.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/initialize.rb#L1>`_





Methods
-------



.. _`Neo4j/ActiveNode/Initialize#called_by`:

**#called_by**
  Returns the value of attribute called_by

  .. hidden-code-block:: ruby

     def called_by
       @called_by
     end



.. _`Neo4j/ActiveNode/Initialize#convert_properties_to`:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
       properties.each_pair do |attr, value|
         next if skip_conversion?(attr, value)
         properties[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end



.. _`Neo4j/ActiveNode/Initialize#init_on_load`:

**#init_on_load**
  called when loading the node from the database

  .. hidden-code-block:: ruby

     def init_on_load(persisted_node, properties)
       self.class.extract_association_attributes!(properties)
       @_persisted_obj = persisted_node
       changed_attributes && changed_attributes.clear
       @attributes = attributes.merge!(properties.stringify_keys)
       self.default_properties = properties
       @attributes = convert_properties_to :ruby, @attributes
     end



.. _`Neo4j/ActiveNode/Initialize#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





