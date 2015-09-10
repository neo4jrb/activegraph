Initialize
==========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/initialize.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/initialize.rb#L2>`_





Methods
-------



.. _`Neo4j/Shared/Initialize#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. code-block:: ruby

     def wrapper
       self
     end





