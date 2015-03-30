Migration
=========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   Migration/AddIdProperty

   Migration/AddClassnames




Constants
---------





Files
-----



  * `lib/neo4j/migration.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/migration.rb#L4>`_





Methods
-------


**#default_path**
  

  .. hidden-code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end


**#joined_path**
  

  .. hidden-code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end


**#migrate**
  

  .. hidden-code-block:: ruby

     def migrate
       fail 'not implemented'
     end


**#output**
  

  .. hidden-code-block:: ruby

     def output(string = '')
       puts string unless !!ENV['silenced']
     end


**#print_output**
  

  .. hidden-code-block:: ruby

     def print_output(string)
       print string unless !!ENV['silenced']
     end





