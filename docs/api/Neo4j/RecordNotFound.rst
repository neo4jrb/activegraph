RecordNotFound
==============



Raised when Neo4j.rb cannot find record by given id.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/errors.rb:8 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/errors.rb#L8>`_





Methods
-------



.. _`Neo4j/RecordNotFound#id`:

**#id**
  Returns the value of attribute id

  .. code-block:: ruby

     def id
       @id
     end



.. _`Neo4j/RecordNotFound#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(message = nil, model = nil, primary_key = nil, id = nil)
       @primary_key = primary_key
       @model = model
       @id = id
     
       super(message)
     end



.. _`Neo4j/RecordNotFound#model`:

**#model**
  Returns the value of attribute model

  .. code-block:: ruby

     def model
       @model
     end



.. _`Neo4j/RecordNotFound#primary_key`:

**#primary_key**
  Returns the value of attribute primary_key

  .. code-block:: ruby

     def primary_key
       @primary_key
     end





