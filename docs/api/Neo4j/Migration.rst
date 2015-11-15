Migration
=========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   Migration/AddIdProperty




Constants
---------





Files
-----



  * `lib/neo4j/migration.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/migration.rb#L4>`_





Methods
-------



.. _`Neo4j/Migration#default_path`:

**#default_path**
  

  .. code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end



.. _`Neo4j/Migration#joined_path`:

**#joined_path**
  

  .. code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end



.. _`Neo4j/Migration#migrate`:

**#migrate**
  

  .. code-block:: ruby

     def migrate
       fail 'not implemented'
     end



.. _`Neo4j/Migration#output`:

**#output**
  

  .. code-block:: ruby

     def output(string = '')
       puts string unless !!ENV['silenced']
     end



.. _`Neo4j/Migration#print_output`:

**#print_output**
  

  .. code-block:: ruby

     def print_output(string)
       print string unless !!ENV['silenced']
     end





