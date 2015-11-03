Index
=====



None of these methods interact with the database. They only keep track of property settings in models.
It could (should?) handle the actual indexing/constraining, but that's TBD.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/declared_property/index.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/declared_property/index.rb#L5>`_





Methods
-------



.. _`Neo4j/Shared/DeclaredProperty/Index#constraint!`:

**#constraint!**
  

  .. code-block:: ruby

     def constraint!(type = :unique)
       fail Neo4j::InvalidPropertyOptionsError, "Unable to set constraint on indexed property #{name}" if index?(:exact)
       options[:constraint] = type
     end



.. _`Neo4j/Shared/DeclaredProperty/Index#constraint?`:

**#constraint?**
  

  .. code-block:: ruby

     def constraint?(type = :unique)
       options.key?(:constraint) && options[:constraint] == type
     end



.. _`Neo4j/Shared/DeclaredProperty/Index#index!`:

**#index!**
  

  .. code-block:: ruby

     def index!(type = :exact)
       fail Neo4j::InvalidPropertyOptionsError, "Unable to set index on constrainted property #{name}" if constraint?(:unique)
       options[:index] = type
     end



.. _`Neo4j/Shared/DeclaredProperty/Index#index?`:

**#index?**
  

  .. code-block:: ruby

     def index?(type = :exact)
       options.key?(:index) && options[:index] == type
     end



.. _`Neo4j/Shared/DeclaredProperty/Index#index_or_constraint?`:

**#index_or_constraint?**
  

  .. code-block:: ruby

     def index_or_constraint?
       index?(:exact) || constraint?(:unique)
     end



.. _`Neo4j/Shared/DeclaredProperty/Index#unconstraint!`:

**#unconstraint!**
  

  .. code-block:: ruby

     def unconstraint!(type = :unique)
       options.delete(:constraint) if constraint?(type)
     end



.. _`Neo4j/Shared/DeclaredProperty/Index#unindex!`:

**#unindex!**
  

  .. code-block:: ruby

     def unindex!(type = :exact)
       options.delete(:index) if index?(type)
     end





