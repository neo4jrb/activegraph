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



.. _`Neo4j/ActiveRel/Initialize#init_on_load`:

**#init_on_load**
  called when loading the rel from the database

  .. code-block:: ruby

     def init_on_load(persisted_rel, from_node_id, to_node_id, type)
       @rel_type = type
       @_persisted_obj = persisted_rel
       changed_attributes && changed_attributes.clear
       @attributes = convert_and_assign_attributes(persisted_rel.props)
       load_nodes(from_node_id, to_node_id)
     end



.. _`Neo4j/ActiveRel/Initialize#init_on_reload`:

**#init_on_reload**
  

  .. code-block:: ruby

     def init_on_reload(unwrapped_reloaded)
       @attributes = nil
       init_on_load(unwrapped_reloaded,
                    unwrapped_reloaded._start_node_id,
                    unwrapped_reloaded._end_node_id,
                    unwrapped_reloaded.rel_type)
       self
     end



.. _`Neo4j/ActiveRel/Initialize#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. code-block:: ruby

     def wrapper
       self
     end





