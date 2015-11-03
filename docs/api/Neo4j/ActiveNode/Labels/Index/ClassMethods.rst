ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/labels/index.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels/index.rb#L5>`_





Methods
-------



.. _`Neo4j/ActiveNode/Labels/Index/ClassMethods#constraint`:

**#constraint**
  Creates a neo4j constraint on this class for given property

  .. code-block:: ruby

     def constraint(property, constraints = {type: :unique})
       Neo4j::Session.on_next_session_available do
         declared_properties.constraint_or_fail!(property, id_property_name)
         schema_create_operation(:constraint, property, constraints)
       end
     end



.. _`Neo4j/ActiveNode/Labels/Index/ClassMethods#constraint?`:

**#constraint?**
  

  .. code-block:: ruby

     def constraint?(property)
       mapped_label.unique_constraints[:property_keys].include?([property])
     end



.. _`Neo4j/ActiveNode/Labels/Index/ClassMethods#drop_constraint`:

**#drop_constraint**
  

  .. code-block:: ruby

     def drop_constraint(property, constraint = {type: :unique})
       Neo4j::Session.on_next_session_available do
         declared_properties[property].unconstraint! if declared_properties[property]
         schema_drop_operation(:constraint, property, constraint)
       end
     end



.. _`Neo4j/ActiveNode/Labels/Index/ClassMethods#drop_index`:

**#drop_index**
  

  .. code-block:: ruby

     def drop_index(property, options = {})
       Neo4j::Session.on_next_session_available do
         declared_properties[property].unindex! if declared_properties[property]
         schema_drop_operation(:index, property, options)
       end
     end



.. _`Neo4j/ActiveNode/Labels/Index/ClassMethods#index`:

**#index**
  Creates a Neo4j index on given property
  
  This can also be done on the property directly, see Neo4j::ActiveNode::Property::ClassMethods#property.

  .. code-block:: ruby

     def index(property)
       Neo4j::Session.on_next_session_available do |_|
         declared_properties.index_or_fail!(property, id_property_name)
         schema_create_operation(:index, property)
       end
     end



.. _`Neo4j/ActiveNode/Labels/Index/ClassMethods#index?`:

**#index?**
  

  .. code-block:: ruby

     def index?(property)
       mapped_label.indexes[:property_keys].include?([property])
     end





