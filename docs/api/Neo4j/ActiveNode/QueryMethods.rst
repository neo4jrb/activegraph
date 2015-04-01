QueryMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   QueryMethods/InvalidParameterError

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query_methods.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query_methods.rb#L3>`_





Methods
-------


.. _QueryMethods_blank?:

**#blank?**
  

  .. hidden-code-block:: ruby

     def empty?
       !self.all.exists?
     end


.. _QueryMethods_count:

**#count**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end


.. _QueryMethods_empty?:

**#empty?**
  

  .. hidden-code-block:: ruby

     def empty?
       !self.all.exists?
     end


.. _QueryMethods_exists?:

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


.. _QueryMethods_find_each:

**#find_each**
  

  .. hidden-code-block:: ruby

     def find_each(options = {})
       self.query_as(:n).return(:n).find_each(:n, primary_key, options) do |batch|
         yield batch.n
       end
     end


.. _QueryMethods_find_in_batches:

**#find_in_batches**
  

  .. hidden-code-block:: ruby

     def find_in_batches(options = {})
       self.query_as(:n).return(:n).find_in_batches(:n, primary_key, options) do |batch|
         yield batch.map(&:n)
       end
     end


.. _QueryMethods_first:

**#first**
  Returns the first node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.

  .. hidden-code-block:: ruby

     def first
       self.query_as(:n).limit(1).order(n: primary_key).pluck(:n).first
     end


.. _QueryMethods_last:

**#last**
  Returns the last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.

  .. hidden-code-block:: ruby

     def last
       self.query_as(:n).limit(1).order(n: {primary_key => :desc}).pluck(:n).first
     end


.. _QueryMethods_length:

**#length**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end


.. _QueryMethods_size:

**#size**
  

  .. hidden-code-block:: ruby

     def count(distinct = nil)
       fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end





