QueryMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query_methods.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query_methods.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/QueryMethods#blank?`:

**#blank?**
  

  .. code-block:: ruby

     def empty?
       !self.all.exists?
     end



.. _`Neo4j/ActiveNode/QueryMethods#count`:

**#count**
  

  .. code-block:: ruby

     def count(distinct = nil)
       fail(Neo4j::InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end



.. _`Neo4j/ActiveNode/QueryMethods#empty?`:

**#empty?**
  

  .. code-block:: ruby

     def empty?
       !self.all.exists?
     end



.. _`Neo4j/ActiveNode/QueryMethods#exists?`:

**#exists?**
  

  .. code-block:: ruby

     def exists?(node_condition = nil)
       unless node_condition.is_a?(Integer) || node_condition.is_a?(Hash) || node_condition.nil?
         fail(Neo4j::InvalidParameterError, ':exists? only accepts ids or conditions')
       end
       query_start = exists_query_start(node_condition)
       start_q = query_start.respond_to?(:query_as) ? query_start.query_as(:n) : query_start
       start_q.return('COUNT(n) AS count').first.count > 0
     end



.. _`Neo4j/ActiveNode/QueryMethods#find_each`:

**#find_each**
  

  .. code-block:: ruby

     def find_each(options = {})
       self.query_as(:n).return(:n).find_each(:n, primary_key, options) do |batch|
         yield batch.n
       end
     end



.. _`Neo4j/ActiveNode/QueryMethods#find_in_batches`:

**#find_in_batches**
  

  .. code-block:: ruby

     def find_in_batches(options = {})
       self.query_as(:n).return(:n).find_in_batches(:n, primary_key, options) do |batch|
         yield batch.map(&:n)
       end
     end



.. _`Neo4j/ActiveNode/QueryMethods#first`:

**#first**
  Returns the first node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.

  .. code-block:: ruby

     def first
       self.query_as(:n).limit(1).order(n: primary_key).pluck(:n).first
     end



.. _`Neo4j/ActiveNode/QueryMethods#last`:

**#last**
  Returns the last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.

  .. code-block:: ruby

     def last
       self.query_as(:n).limit(1).order(n: {primary_key => :desc}).pluck(:n).first
     end



.. _`Neo4j/ActiveNode/QueryMethods#length`:

**#length**
  

  .. code-block:: ruby

     def count(distinct = nil)
       fail(Neo4j::InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end



.. _`Neo4j/ActiveNode/QueryMethods#size`:

**#size**
  

  .. code-block:: ruby

     def count(distinct = nil)
       fail(Neo4j::InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
       q = distinct.nil? ? 'n' : 'DISTINCT n'
       self.query_as(:n).return("count(#{q}) AS count").first.count
     end





