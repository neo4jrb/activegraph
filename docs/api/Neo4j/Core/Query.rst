Query
=====






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/core/query.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/core/query.rb#L2>`_





Methods
-------



.. _`Neo4j/Core/Query#proxy_as`:

**#proxy_as**
  Creates a Neo4j::ActiveNode::Query::QueryProxy object that builds off of a Core::Query object.

  .. code-block:: ruby

     def proxy_as(model, var, optional = false)
       # TODO: Discuss whether it's necessary to call `break` on the query or if this should be left to the user.
       Neo4j::ActiveNode::Query::QueryProxy.new(model, nil, node: var, optional: optional, starting_query: self, chain_level: @proxy_chain_level)
     end



.. _`Neo4j/Core/Query#proxy_as_optional`:

**#proxy_as_optional**
  Calls proxy_as with `optional` set true. This doesn't offer anything different from calling `proxy_as` directly but it may be more readable.

  .. code-block:: ruby

     def proxy_as_optional(model, var)
       proxy_as(model, var, true)
     end



.. _`Neo4j/Core/Query#proxy_chain_level`:

**#proxy_chain_level**
  For instances where you turn a QueryProxy into a Query and then back to a QueryProxy with `#proxy_as`

  .. code-block:: ruby

     def proxy_chain_level
       @proxy_chain_level
     end



.. _`Neo4j/Core/Query#proxy_chain_level=`:

**#proxy_chain_level=**
  For instances where you turn a QueryProxy into a Query and then back to a QueryProxy with `#proxy_as`

  .. code-block:: ruby

     def proxy_chain_level=(value)
       @proxy_chain_level = value
     end





