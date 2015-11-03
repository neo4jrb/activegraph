AddClassnames
=============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/migration.rb:127 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/migration.rb#L127>`_





Methods
-------



.. _`Neo4j/Migration/AddClassnames#default_path`:

**#default_path**
  

  .. code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end



.. _`Neo4j/Migration/AddClassnames#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(path = default_path)
       @classnames_filename = 'add_classnames.yml'
       @classnames_filepath = File.join(joined_path(path), classnames_filename)
     end



.. _`Neo4j/Migration/AddClassnames#joined_path`:

**#joined_path**
  

  .. code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end



.. _`Neo4j/Migration/AddClassnames#migrate`:

**#migrate**
  

  .. code-block:: ruby

     def migrate
       output 'Adding classnames. This make take some time.'
       execute(true)
     end



.. _`Neo4j/Migration/AddClassnames#output`:

**#output**
  

  .. code-block:: ruby

     def output(string = '')
       puts string unless !!ENV['silenced']
     end



.. _`Neo4j/Migration/AddClassnames#print_output`:

**#print_output**
  

  .. code-block:: ruby

     def print_output(string)
       print string unless !!ENV['silenced']
     end



.. _`Neo4j/Migration/AddClassnames#setup`:

**#setup**
  

  .. code-block:: ruby

     def setup
       output "Creating file #{classnames_filepath}. Please use this as the migration guide."
       FileUtils.mkdir_p('db/neo4j-migrate')
     
       return if File.file?(classnames_filepath)
     
       source = File.join(File.dirname(__FILE__), '..', '..', 'config', 'neo4j', classnames_filename)
       FileUtils.copy_file(source, classnames_filepath)
     end



.. _`Neo4j/Migration/AddClassnames#test`:

**#test**
  

  .. code-block:: ruby

     def test
       output 'TESTING! No queries will be executed.'
       execute(false)
     end





