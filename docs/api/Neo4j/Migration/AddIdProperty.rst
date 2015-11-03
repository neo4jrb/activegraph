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



.. _`Neo4j/Migration/AddIdProperty#default_path`:

**#default_path**
  

  .. code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end



.. _`Neo4j/Migration/AddIdProperty#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(path = default_path)
       @models_filename = File.join(joined_path(path), 'add_id_property.yml')
     end



.. _`Neo4j/Migration/AddIdProperty#joined_path`:

**#joined_path**
  

  .. code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end



.. _`Neo4j/Migration/AddIdProperty#migrate`:

**#migrate**
  

  .. code-block:: ruby

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



.. _`Neo4j/Migration/AddIdProperty#models_filename`:

**#models_filename**
  Returns the value of attribute models_filename

  .. code-block:: ruby

     def models_filename
       @models_filename
     end



.. _`Neo4j/Migration/AddIdProperty#output`:

**#output**
  

  .. code-block:: ruby

     def output(string = '')
       puts string unless !!ENV['silenced']
     end



.. _`Neo4j/Migration/AddIdProperty#print_output`:

**#print_output**
  

  .. code-block:: ruby

     def print_output(string)
       print string unless !!ENV['silenced']
     end



.. _`Neo4j/Migration/AddIdProperty#setup`:

**#setup**
  

  .. code-block:: ruby

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





