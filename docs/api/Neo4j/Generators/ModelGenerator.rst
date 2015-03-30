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


**#create_model_file**
  

  .. hidden-code-block:: ruby

     def create_model_file
       template 'model.erb', File.join('app/models', "#{singular_name}.rb")
     end


**#has_many?**
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_many?
       options[:has_many]
     end


**#has_many_statements**
  

  .. hidden-code-block:: ruby

     def has_many_statements
       txt = ''
       options[:has_many].each do |key|
         txt << has_x('has_many', key)
       end
       txt
     end


**#has_one?**
  

  .. hidden-code-block:: ruby

     def has_one?
       options[:has_one]
     end


**#has_one_statements**
  

  .. hidden-code-block:: ruby

     def has_one_statements
       txt = ''
       options[:has_one].each do |key|
         txt << has_x('has_one', key)
       end
       txt
     end


**#has_x**
  

  .. hidden-code-block:: ruby

     def has_x(method, key)
       to, from = key.split(':')
       (from ? "\n  #{method}(:#{to}).from(:#{from})\n" : "\n  #{method} :#{to}")
     end


**#index_fragment**
  

  .. hidden-code-block:: ruby

     def index_fragment(property)
       return if !options[:indices] || !options[:indices].include?(property)
     
       "index :#{property}"
     end


**#indices?**
  rubocop:enable Style/PredicateName

  .. hidden-code-block:: ruby

     def indices?
       options[:indices]
     end


**#migration?**
  

  .. hidden-code-block:: ruby

     def migration?
       false
     end


**#parent?**
  

  .. hidden-code-block:: ruby

     def parent?
       options[:parent]
     end


**#source_root**
  

  .. hidden-code-block:: ruby

     def self.source_root
       @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                          'neo4j', generator_name, 'templates'))
     end


**#timestamp_statements**
  

  .. hidden-code-block:: ruby

     def timestamp_statements
       '
     property :created_at, type: DateTime
     # property :created_on, type: Date
     
     property :updated_at, type: DateTime
     # property :updated_on, type: Date
     
     '
     end


**#timestamps?**
  

  .. hidden-code-block:: ruby

     def timestamps?
       options[:timestamps]
     end





