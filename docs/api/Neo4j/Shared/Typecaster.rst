Typecaster
==========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/shared/typecaster.rb:43 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/typecaster.rb#L43>`_





Methods
-------


**#included**
  

  .. hidden-code-block:: ruby

     def self.included(other)
       Neo4j::Shared::TypeConverters.register_converter(other)
     end





