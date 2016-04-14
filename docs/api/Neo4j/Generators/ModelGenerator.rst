ModelGenerator
==============



:nodoc:


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/rails/generators/neo4j/model/model_generator.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/rails/generators/neo4j/model/model_generator.rb#L3>`_





Methods
-------



.. _`Neo4j/Generators/ModelGenerator#create_model_file`:

**#create_model_file**
  

  .. code-block:: ruby

     def create_model_file
       template 'model.erb', File.join('app/models', class_path, "#{singular_name}.rb")
     end



.. _`Neo4j/Generators/ModelGenerator.source_root`:

**.source_root**
  

  .. code-block:: ruby

     def self.source_root
       @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                          'neo4j', generator_name, 'templates'))
     end





