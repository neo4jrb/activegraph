AddClassnames
=============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/migration.rb:127





Methods
-------


**#action_variables**
  

  .. hidden-code-block:: ruby

     def action_variables(action, identifier)
       case action
       when 'overwrite'
         ['', 'Overwriting']
       when 'add'
         ["WHERE NOT HAS(#{identifier}._classname)", 'Adding']
       else
         fail "Invalid action #{action} specified"
       end
     end


**#classnames_filename**
  Returns the value of attribute classnames_filename

  .. hidden-code-block:: ruby

     def classnames_filename
       @classnames_filename
     end


**#classnames_filepath**
  Returns the value of attribute classnames_filepath

  .. hidden-code-block:: ruby

     def classnames_filepath
       @classnames_filepath
     end


**#default_path**
  

  .. hidden-code-block:: ruby

     def default_path
       Rails.root if defined? Rails
     end


**#do_classnames**
  

  .. hidden-code-block:: ruby

     def do_classnames(action, labels, type, migrate = false)
       method = type == :nodes ? :node_cypher : :rel_cypher
       labels.each do |label|
         output cypher = self.send(method, label, action)
         execute_cypher(cypher) if migrate
       end
     end


**#execute**
  

  .. hidden-code-block:: ruby

     def execute(migrate = false)
       file_init
       map = []
       map.push :nodes         if model_map[:nodes]
       map.push :relationships if model_map[:relationships]
       map.each do |type|
         model_map[type].each do |action, labels|
           do_classnames(action, labels, type, migrate)
         end
       end
     end


**#execute_cypher**
  

  .. hidden-code-block:: ruby

     def execute_cypher(query_string)
       output "Modified #{Neo4j::Session.query(query_string).first.modified} records"
       output ''
     end


**#file_init**
  

  .. hidden-code-block:: ruby

     def file_init
       @model_map = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(classnames_filepath))
     end


**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(path = default_path)
       @classnames_filename = 'add_classnames.yml'
       @classnames_filepath = File.join(joined_path(path), classnames_filename)
     end


**#joined_path**
  

  .. hidden-code-block:: ruby

     def joined_path(path)
       File.join(path.to_s, 'db', 'neo4j-migrate')
     end


**#migrate**
  

  .. hidden-code-block:: ruby

     def migrate
       output 'Adding classnames. This make take some time.'
       execute(true)
     end


**#model_map**
  Returns the value of attribute model_map

  .. hidden-code-block:: ruby

     def model_map
       @model_map
     end


**#node_cypher**
  

  .. hidden-code-block:: ruby

     def node_cypher(label, action)
       where, phrase_start = action_variables(action, 'n')
       output "#{phrase_start} _classname '#{label}' on nodes with matching label:"
       "MATCH (n:`#{label}`) #{where} SET n._classname = '#{label}' RETURN COUNT(n) as modified"
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


**#rel_cypher**
  

  .. hidden-code-block:: ruby

     def rel_cypher(hash, action)
       label = hash[0]
       value = hash[1]
       from = value[:from]
       fail "All relationships require a 'type'" unless value[:type]
     
       from_cypher = from ? "(from:`#{from}`)" : '(from)'
       to = value[:to]
       to_cypher = to ? "(to:`#{to}`)" : '(to)'
       type = "[r:`#{value[:type]}`]"
       where, phrase_start = action_variables(action, 'r')
       output "#{phrase_start} _classname '#{label}' where type is '#{value[:type]}' using cypher:"
       "MATCH #{from_cypher}-#{type}->#{to_cypher} #{where} SET r._classname = '#{label}' return COUNT(r) as modified"
     end


**#setup**
  

  .. hidden-code-block:: ruby

     def setup
       output "Creating file #{classnames_filepath}. Please use this as the migration guide."
       FileUtils.mkdir_p('db/neo4j-migrate')
     
       return if File.file?(classnames_filepath)
     
       source = File.join(File.dirname(__FILE__), '..', '..', 'config', 'neo4j', classnames_filename)
       FileUtils.copy_file(source, classnames_filepath)
     end


**#test**
  

  .. hidden-code-block:: ruby

     def test
       output 'TESTING! No queries will be executed.'
       execute(false)
     end





