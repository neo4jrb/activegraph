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


.. _Identity_==:

**#==**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end


.. _Identity_eql?:

**#eql?**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end


.. _Identity_hash:

**#hash**
  

  .. hidden-code-block:: ruby

     def hash
       id.hash
     end


.. _Identity_id:

**#id**
  

  .. hidden-code-block:: ruby

     def id
       id = neo_id
       id.is_a?(Integer) ? id : nil
     end


.. _Identity_neo_id:

**#neo_id**
  

  .. hidden-code-block:: ruby

     def neo_id
       _persisted_obj ? _persisted_obj.neo_id : nil
     end


.. _Identity_to_key:

**#to_key**
  Returns an Enumerable of all (primary) key attributes
  or nil if model.persisted? is false

  .. hidden-code-block:: ruby

     def to_key
       persisted? ? [id] : nil
     end





