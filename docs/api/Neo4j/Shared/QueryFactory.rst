QueryFactory
============



Acts as a bridge between the node and rel models and Neo4j::Core::Query.
If the object is persisted, it returns a query matching; otherwise, it returns a query creating it.
This class does not execute queries, so it keeps no record of what identifiers have been set or what has happened in previous factories.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/query_factory.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/query_factory.rb#L5>`_





Methods
-------



.. _`Neo4j/Shared/QueryFactory#base_query`:

**#base_query**
  

  .. code-block:: ruby

     def base_query
       @base_query || Neo4j::Session.current.query
     end



.. _`Neo4j/Shared/QueryFactory#base_query=`:

**#base_query=**
  

  .. code-block:: ruby

     def base_query=(query)
       return if query.blank?
       @base_query = query
     end



.. _`Neo4j/Shared/QueryFactory.create`:

**.create**
  

  .. code-block:: ruby

     def self.create(graph_object, identifier)
       factory_for(graph_object).new(graph_object, identifier)
     end



.. _`Neo4j/Shared/QueryFactory.factory_for`:

**.factory_for**
  

  .. code-block:: ruby

     def self.factory_for(graph_obj)
       case
       when graph_obj.respond_to?(:labels_for_create)
         NodeQueryFactory
       when graph_obj.respond_to?(:rel_type)
         RelQueryFactory
       else
         fail "Unable to find factory for #{graph_obj}"
       end
     end



.. _`Neo4j/Shared/QueryFactory#graph_object`:

**#graph_object**
  Returns the value of attribute graph_object

  .. code-block:: ruby

     def graph_object
       @graph_object
     end



.. _`Neo4j/Shared/QueryFactory#identifier`:

**#identifier**
  Returns the value of attribute identifier

  .. code-block:: ruby

     def identifier
       @identifier
     end



.. _`Neo4j/Shared/QueryFactory#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(graph_object, identifier)
       @graph_object = graph_object
       @identifier = identifier.to_sym
     end



.. _`Neo4j/Shared/QueryFactory#query`:

**#query**
  

  .. code-block:: ruby

     def query
       graph_object.persisted? ? match_query : create_query
     end





