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


.. _AddClassnames_default_path:

**#default_path**
  

  .. hidden-code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end


.. _AddClassnames_initialize:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(path = default_path)
       @classnames_filename = 'add_classnames.yml'
       @classnames_filepath = File.join(joined_path(path), classnames_filename)
     end


.. _AddClassnames_joined_path:

**#joined_path**
  

  .. hidden-code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end


.. _AddClassnames_migrate:

**#migrate**
  

  .. hidden-code-block:: ruby

     def migrate
       output 'Adding classnames. This make take some time.'
       execute(true)
     end


.. _AddClassnames_output:

**#output**
  

  .. hidden-code-block:: ruby

     def output(string = '')
       puts string unless !!ENV['silenced']
     end


.. _AddClassnames_print_output:

**#print_output**
  

  .. hidden-code-block:: ruby

     def print_output(string)
       print string unless !!ENV['silenced']
     end


.. _AddClassnames_setup:

**#setup**
  

  .. hidden-code-block:: ruby

     def setup
       output "Creating file #{classnames_filepath}. Please use this as the migration guide."
       FileUtils.mkdir_p('db/neo4j-migrate')
     
       return if File.file?(classnames_filepath)
     
       source = File.join(File.dirname(__FILE__), '..', '..', 'config', 'neo4j', classnames_filename)
       FileUtils.copy_file(source, classnames_filepath)
     end


.. _AddClassnames_test:

**#test**
  

  .. hidden-code-block:: ruby

     def test
       output 'TESTING! No queries will be executed.'
       execute(false)
     end





