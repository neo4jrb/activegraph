Base
====




.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * lib/rails/generators/neo4j_generator.rb:10





Methods
-------


**#source_root**
  

  .. hidden-code-block:: ruby

     def self.source_root
       @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                          'neo4j', generator_name, 'templates'))
     end





