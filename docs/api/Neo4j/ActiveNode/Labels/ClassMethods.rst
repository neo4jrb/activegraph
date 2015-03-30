ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/labels.rb:82 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels.rb#L82>`_





Methods
-------


**#_index**
  

  .. hidden-code-block:: ruby

     def _index(property, conf)
       mapped_labels.each do |label|
         # make sure the property is not indexed twice
         existing = label.indexes[:property_keys]
     
         # In neo4j constraint automatically creates an index
         if conf[:constraint]
           constraint(property, conf[:constraint])
         else
           label.create_index(property) unless existing.flatten.include?(property)
         end
       end
     end


**#all**
  Find all nodes/objects of this class

  .. hidden-code-block:: ruby

     def all
       Neo4j::ActiveNode::Query::QueryProxy.new(self, nil, {})
     end


**#base_class**
  

  .. hidden-code-block:: ruby

     def base_class
       unless self < Neo4j::ActiveNode
         fail "#{name} doesn't belong in a hierarchy descending from ActiveNode"
       end
     
       if superclass == Object
         self
       else
         superclass.base_class
       end
     end


**#blank?**
  

  .. hidden-code-block:: ruby

     def empty?
       !self.all.exists?
     end


**#constraint**
  Creates a neo4j constraint on this class for given property

  .. hidden-code-block:: ruby

     def constraint(property, constraints)
       Neo4j::Session.on_session_available do |session|
         unless Neo4j::Label.constraint?(mapped_label_name, property)
           label = Neo4j::Label.create(mapped_label_name)
           label.create_constraint(property, constraints, session)
         end
       end
     end


**#count**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end


**#delete_all**
  Deletes all nodes and connected relationships from Cypher.

  .. hidden-code-block:: ruby

     def delete_all
       self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) OPTIONAL MATCH n-[r]-() DELETE n,r")
       self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) DELETE n")
     end


**#destroy_all**
  Returns each node to Ruby and calls `destroy`. Be careful, as this can be a very slow operation if you have many nodes. It will generate at least
  one database query per node in the database, more if callbacks require them.

  .. hidden-code-block:: ruby

     def destroy_all
       all.each(&:destroy)
     end


**#drop_constraint**
  

  .. hidden-code-block:: ruby

     def drop_constraint(property, constraint)
       Neo4j::Session.on_session_available do |session|
         label = Neo4j::Label.create(mapped_label_name)
         label.drop_constraint(property, constraint, session)
       end
     end


**#empty?**
  

  .. hidden-code-block:: ruby

     def empty?
       !self.all.exists?
     end


**#exists?**
  

  .. hidden-code-block:: ruby

     def exists?(node_condition = nil)
       unless node_condition.is_a?(Integer) || node_condition.is_a?(Hash) || node_condition.nil?
         fail(InvalidParameterError, ':exists? only accepts ids or conditions')
       end
       query_start = exists_query_start(node_condition)
       start_q = query_start.respond_to?(:query_as) ? query_start.query_as(:n) : query_start
       start_q.return('COUNT(n) AS count').first.count > 0
     end


**#exists_query_start**
  

  .. hidden-code-block:: ruby

     def exists_query_start(node_condition)
       case node_condition
       when Integer
         self.query_as(:n).where('ID(n)' => node_condition)
       when Hash
         self.where(node_condition.keys.first => node_condition.values.first)
       else
         self.query_as(:n)
       end
     end


**#find**
  Returns the object with the specified neo4j id.

  .. hidden-code-block:: ruby

     def find(id)
       map_id = proc { |object| object.respond_to?(:id) ? object.send(:id) : object }
     
       if id.is_a?(Array)
         find_by_ids(id.map { |o| map_id.call(o) })
       else
         find_by_id(map_id.call(id))
       end
     end


**#find_by**
  Finds the first record matching the specified conditions. There is no implied ordering so if order matters, you should specify it yourself.

  .. hidden-code-block:: ruby

     def find_by(values)
       all.query_as(:n).where(n: values).limit(1).pluck(:n).first
     end


**#find_by!**
  Like find_by, except that if no record is found, raises a RecordNotFound error.

  .. hidden-code-block:: ruby

     def find_by!(values)
       find_by(values) || fail(RecordNotFound, "#{self.query_as(:n).where(n: values).limit(1).to_cypher} returned no results")
     end


**#find_each**
  

  .. hidden-code-block:: ruby

     def find_each(options = {})
       self.query_as(:n).return(:n).find_each(:n, primary_key, options) do |batch|
         yield batch.n
       end
     end


**#find_in_batches**
  

  .. hidden-code-block:: ruby

     def find_in_batches(options = {})
       self.query_as(:n).return(:n).find_in_batches(:n, primary_key, options) do |batch|
         yield batch.map(&:n)
       end
     end


**#first**
  Returns the first node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.

  .. hidden-code-block:: ruby

     def first
       self.query_as(:n).limit(1).order(n: primary_key).pluck(:n).first
     end


**#index**
  Creates a Neo4j index on given property
  
  This can also be done on the property directly, see Neo4j::ActiveNode::Property::ClassMethods#property.

  .. hidden-code-block:: ruby

     def index(property, conf = {})
       Neo4j::Session.on_session_available do |_|
         _index(property, conf)
       end
       indexed_properties.push property unless indexed_properties.include? property
     end


**#index?**
  

  .. hidden-code-block:: ruby

     def index?(index_def)
       mapped_label.indexes[:property_keys].include?([index_def])
     end


**#indexed_properties**
  

  .. hidden-code-block:: ruby

     def indexed_properties
       @_indexed_properties ||= []
     end


**#last**
  Returns the last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.

  .. hidden-code-block:: ruby

     def last
       self.query_as(:n).limit(1).order(n: {primary_key => :desc}).pluck(:n).first
     end


**#length**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end


**#mapped_label**
  

  .. hidden-code-block:: ruby

     def mapped_label
       Neo4j::Label.create(mapped_label_name)
     end


**#mapped_label_name**
  

  .. hidden-code-block:: ruby

     def mapped_label_name
       @mapped_label_name || (self.name.nil? ? object_id.to_s.to_sym : self.name.to_sym)
     end


**#mapped_label_name=**
  

  .. hidden-code-block:: ruby

     def mapped_label_name=(name)
       @mapped_label_name = name.to_sym
     end


**#mapped_label_names**
  

  .. hidden-code-block:: ruby

     def mapped_label_names
       self.ancestors.find_all { |a| a.respond_to?(:mapped_label_name) }.map { |a| a.mapped_label_name.to_sym }
     end


**#mapped_labels**
  

  .. hidden-code-block:: ruby

     def mapped_labels
       mapped_label_names.map { |label_name| Neo4j::Label.create(label_name) }
     end


**#set_mapped_label_name**
  rubocop:disable Style/AccessorMethodName

  .. hidden-code-block:: ruby

     def set_mapped_label_name(name)
       ActiveSupport::Deprecation.warn 'set_mapped_label_name is deprecated, use self.mapped_label_name= instead.', caller
     
       self.mapped_label_name = name
     end


**#size**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end





