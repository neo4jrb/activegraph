RecordInvalidError
==================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/persistence.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/persistence.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/Persistence/RecordInvalidError#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(record)
       @record = record
       super(@record.errors.full_messages.join(', '))
     end



.. _`Neo4j/ActiveNode/Persistence/RecordInvalidError#record`:

**#record**
  Returns the value of attribute record

  .. code-block:: ruby

     def record
       @record
     end





