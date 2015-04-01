AddIdProperty
=============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/migration.rb:25 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/migration.rb#L25>`_





Methods
-------


.. _AddIdProperty_default_path:

**#default_path**
  

  .. hidden-code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end


.. _AddIdProperty_initialize:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(path = default_path)
       @models_filename = File.join(joined_path(path), 'add_id_property.yml')
     end


.. _AddIdProperty_joined_path:

**#joined_path**
  

  .. hidden-code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end


.. _AddIdProperty_migrate:

**#migrate**
  

  .. hidden-code-block:: ruby

     def migrate
       models = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(models_filename))[:models]
       output 'This task will add an ID Property every node in the given file.'
       output 'It may take a significant amount of time, please be patient.'
       models.each do |model|
         output
         output
         output "Adding IDs to #{model}"
         add_ids_to model.constantize
       end
     end


.. _AddIdProperty_models_filename:

**#models_filename**
  Returns the value of attribute models_filename

  .. hidden-code-block:: ruby

     def models_filename
       @models_filename
     end


.. _AddIdProperty_output:

**#output**
  

  .. hidden-code-block:: ruby

     def output(string = '')
       puts string unless !!ENV['silenced']
     end


.. _AddIdProperty_print_output:

**#print_output**
  

  .. hidden-code-block:: ruby

     def print_output(string)
       print string unless !!ENV['silenced']
     end


.. _AddIdProperty_setup:

**#setup**
  

  .. hidden-code-block:: ruby

     def setup
       FileUtils.mkdir_p('db/neo4j-migrate')
     
       return if File.file?(models_filename)
     
       File.open(models_filename, 'w') do |file|
         message = <<MESSAGE
     # Provide models to which IDs should be added.
     # # It will only modify nodes that do not have IDs. There is no danger of overwriting data.
     # # models: [Student,Lesson,Teacher,Exam]\nmodels: []
     MESSAGE
         file.write(message)
       end
     end





