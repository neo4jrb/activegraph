ModelGenerator
==============




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


.. _ModelGenerator_create_model_file:

**#create_model_file**
  

  .. hidden-code-block:: ruby

     def create_model_file
       template 'model.erb', File.join('app/models', "#{singular_name}.rb")
     end


.. _ModelGenerator_source_root:

**.source_root**
  

  .. hidden-code-block:: ruby

     def self.source_root
       @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                          'neo4j', generator_name, 'templates'))
     end





