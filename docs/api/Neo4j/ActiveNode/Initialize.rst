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

  .. code-block:: ruby

     def called_by
       @called_by
     end



.. _`Neo4j/ActiveNode/Initialize#init_on_load`:

**#init_on_load**
  called when loading the node from the database

  .. code-block:: ruby

     def init_on_load(persisted_node, properties)
       self.class.extract_association_attributes!(properties)
       @_persisted_obj = persisted_node
       changed_attributes && changed_attributes.clear
       @attributes = convert_and_assign_attributes(properties)
     end



.. _`Neo4j/ActiveNode/Initialize#init_on_reload`:

**#init_on_reload**
  

  .. code-block:: ruby

     def init_on_reload(reloaded)
       @attributes = nil
       init_on_load(reloaded, reloaded.props)
     end



.. _`Neo4j/ActiveNode/Initialize#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. code-block:: ruby

     def wrapper
       self
     end





