RelabelRelationships
====================






.. toctree::
   :maxdepth: 3
   :titlesonly:































Constants
---------



  * MESSAGE



Files
-----



  * `lib/neo4j/migration.rb:130 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/migration.rb#L130>`_





Methods
-------



.. _`Neo4j/Migration/RelabelRelationships#default_path`:

**#default_path**


  .. code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end



.. _`Neo4j/Migration/RelabelRelationships#initialize`:

**#initialize**


  .. code-block:: ruby

     def initialize(path = default_path)
       @relationships_filename = File.join(joined_path(path), 'relabel_relationships.yml')
     end



.. _`Neo4j/Migration/RelabelRelationships#joined_path`:

**#joined_path**


  .. code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end



.. _`Neo4j/Migration/RelabelRelationships#migrate`:

**#migrate**


  .. code-block:: ruby

     def migrate
       config        = YAML.load_file(relationships_filename).to_hash
       relationships = config['relationships']
       @old_format   = config['formats']['old']
       @new_format   = config['formats']['new']

       output 'This task will relabel every given relationship.'
       output 'It may take a significant amount of time, please be patient.'
       relationships.each { |relationship| reindex relationship }
     end



.. _`Neo4j/Migration/RelabelRelationships#new_format`:

**#new_format**
  Returns the value of attribute new_format

  .. code-block:: ruby

     def new_format
       @new_format
     end



.. _`Neo4j/Migration/RelabelRelationships#new_format=`:

**#new_format=**
  Sets the attribute new_format

  .. code-block:: ruby

     def new_format=(value)
       @new_format = value
     end



.. _`Neo4j/Migration/RelabelRelationships#old_format`:

**#old_format**
  Returns the value of attribute old_format

  .. code-block:: ruby

     def old_format
       @old_format
     end



.. _`Neo4j/Migration/RelabelRelationships#old_format=`:

**#old_format=**
  Sets the attribute old_format

  .. code-block:: ruby

     def old_format=(value)
       @old_format = value
     end



.. _`Neo4j/Migration/RelabelRelationships#output`:

**#output**


  .. code-block:: ruby

     def output(string = '')
       puts string unless !!ENV['silenced']
     end



.. _`Neo4j/Migration/RelabelRelationships#print_output`:

**#print_output**


  .. code-block:: ruby

     def print_output(string)
       print string unless !!ENV['silenced']
     end



.. _`Neo4j/Migration/RelabelRelationships#relationships_filename`:

**#relationships_filename**
  Returns the value of attribute relationships_filename

  .. code-block:: ruby

     def relationships_filename
       @relationships_filename
     end



.. _`Neo4j/Migration/RelabelRelationships#relationships_filename=`:

**#relationships_filename=**
  Sets the attribute relationships_filename

  .. code-block:: ruby

     def relationships_filename=(value)
       @relationships_filename = value
     end



.. _`Neo4j/Migration/RelabelRelationships#setup`:

**#setup**


  .. code-block:: ruby

     def setup
       super
       return if File.file?(relationships_filename)
       File.open(relationships_filename, 'w') { |f| f.write(MESSAGE) }
     end
