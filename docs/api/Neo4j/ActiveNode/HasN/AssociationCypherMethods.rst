AssociationCypherMethods
========================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * VALID_REL_LENGTH_SYMBOLS



Files
-----



  * `lib/neo4j/active_node/has_n/association_cypher_methods.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association_cypher_methods.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/HasN/AssociationCypherMethods#arrow_cypher`:

**#arrow_cypher**
  Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)

  .. code-block:: ruby

     def arrow_cypher(var = nil, properties = {}, create = false, reverse = false, length = nil)
       validate_origin!
     
       if create && length.present?
         fail(ArgumentError, 'rel_length option cannot be specified when creating a relationship')
       end
     
       direction_cypher(get_relationship_cypher(var, properties, create, length), create, reverse)
     end





