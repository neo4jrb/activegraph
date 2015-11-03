ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/query.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/query.rb#L5>`_





Methods
-------



.. _`Neo4j/ActiveRel/Query/ClassMethods#all`:

**#all**
  Performs a basic match on the relationship, returning all results.
  This is not executed lazily, it will immediately return matching objects.

  .. code-block:: ruby

     def all
       all_query.pluck(:r1)
     end



.. _`Neo4j/ActiveRel/Query/ClassMethods#find`:

**#find**
  Returns the object with the specified neo4j id.

  .. code-block:: ruby

     def find(id, session = self.neo4j_session)
       fail "Unknown argument #{id.class} in find method (expected String or Integer)" if !(id.is_a?(String) || id.is_a?(Integer))
       find_by_id(id, session)
     end



.. _`Neo4j/ActiveRel/Query/ClassMethods#find_by_id`:

**#find_by_id**
  Loads the relationship using its neo_id.

  .. code-block:: ruby

     def find_by_id(key, session = Neo4j::Session.current!)
       session.query.match('()-[r]-()').where('ID(r)' => key.to_i).limit(1).return(:r).first.r
     end



.. _`Neo4j/ActiveRel/Query/ClassMethods#first`:

**#first**
  

  .. code-block:: ruby

     def first
       all_query.limit(1).order('ID(r1)').pluck(:r1).first
     end



.. _`Neo4j/ActiveRel/Query/ClassMethods#last`:

**#last**
  

  .. code-block:: ruby

     def last
       all_query.limit(1).order('ID(r1) DESC').pluck(:r1).first
     end



.. _`Neo4j/ActiveRel/Query/ClassMethods#where`:

**#where**
  Performs a very basic match on the relationship.
  This is not executed lazily, it will immediately return matching objects.
  To use a string, prefix the property with "r1"

  .. code-block:: ruby

     def where(args = {})
       where_query.where(where_string(args)).pluck(:r1)
     end





