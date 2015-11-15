CreateMethod
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/cypher.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/cypher.rb#L3>`_





Methods
-------



.. _`Neo4j/Shared/Cypher/CreateMethod#create_method`:

**#create_method**
  

  .. code-block:: ruby

     def create_method
       creates_unique? ? :create_unique : :create
     end



.. _`Neo4j/Shared/Cypher/CreateMethod#creates_unique`:

**#creates_unique**
  

  .. code-block:: ruby

     def creates_unique(option = :none)
       option = :none if option == true
       @creates_unique = option
     end



.. _`Neo4j/Shared/Cypher/CreateMethod#creates_unique?`:

**#creates_unique?**
  

  .. code-block:: ruby

     def creates_unique?
       !!@creates_unique
     end



.. _`Neo4j/Shared/Cypher/CreateMethod#creates_unique_option`:

**#creates_unique_option**
  

  .. code-block:: ruby

     def creates_unique_option
       @creates_unique || :none
     end



.. _`Neo4j/Shared/Cypher/CreateMethod#unique?`:

**#unique?**
  

  .. code-block:: ruby

     def creates_unique?
       !!@creates_unique
     end





