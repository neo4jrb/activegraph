FilteredHash
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   FilteredHash/InvalidHashFilterType

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * VALID_SYMBOL_INSTRUCTIONS

  * VALID_HASH_INSTRUCTIONS

  * VALID_INSTRUCTIONS_TYPES



Files
-----



  * `lib/neo4j/shared/filtered_hash.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/filtered_hash.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/FilteredHash#base`:

**#base**
  Returns the value of attribute base

  .. code-block:: ruby

     def base
       @base
     end



.. _`Neo4j/Shared/FilteredHash#filtered_base`:

**#filtered_base**
  

  .. code-block:: ruby

     def filtered_base
       case instructions
       when Symbol
         filtered_base_by_symbol
       when Hash
         filtered_base_by_hash
       end
     end



.. _`Neo4j/Shared/FilteredHash#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(base, instructions)
       @base = base
       @instructions = instructions
       @instructions_type = instructions.class
       validate_instructions!(instructions)
     end



.. _`Neo4j/Shared/FilteredHash#instructions`:

**#instructions**
  Returns the value of attribute instructions

  .. code-block:: ruby

     def instructions
       @instructions
     end



.. _`Neo4j/Shared/FilteredHash#instructions_type`:

**#instructions_type**
  Returns the value of attribute instructions_type

  .. code-block:: ruby

     def instructions_type
       @instructions_type
     end





