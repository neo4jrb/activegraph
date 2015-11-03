Base
====



:nodoc:


.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/rails/generators/neo4j_generator.rb:10 <https://github.com/neo4jrb/neo4j/blob/master/lib/rails/generators/neo4j_generator.rb#L10>`_





Methods
-------



.. _`Neo4j/Generators/Base.source_root`:

**.source_root**
  

  .. code-block:: ruby

     def self.source_root
       @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                          'neo4j', generator_name, 'templates'))
     end





