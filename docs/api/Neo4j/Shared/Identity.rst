Identity
========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/identity.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/identity.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/Identity#==`:

**#==**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end



.. _`Neo4j/Shared/Identity#eql?`:

**#eql?**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end



.. _`Neo4j/Shared/Identity#hash`:

**#hash**
  

  .. hidden-code-block:: ruby

     def hash
       id.hash
     end



.. _`Neo4j/Shared/Identity#id`:

**#id**
  

  .. hidden-code-block:: ruby

     def id
       id = neo_id
       id.is_a?(Integer) ? id : nil
     end



.. _`Neo4j/Shared/Identity#neo_id`:

**#neo_id**
  

  .. hidden-code-block:: ruby

     def neo_id
       _persisted_obj ? _persisted_obj.neo_id : nil
     end



.. _`Neo4j/Shared/Identity#to_key`:

**#to_key**
  Returns an Enumerable of all (primary) key attributes
  or nil if model.persisted? is false

  .. hidden-code-block:: ruby

     def to_key
       persisted? ? [id] : nil
     end





