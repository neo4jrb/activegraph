ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_rel/query.rb:5





Methods
-------


**#all**
  Performs a basic match on the relationship, returning all results.
  This is not executed lazily, it will immediately return matching objects.

  .. hidden-code-block:: ruby

     def all
       all_query.pluck(:r1)
     end


**#all_query**
  

  .. hidden-code-block:: ruby

     def all_query
       Neo4j::Session.query.match("#{cypher_string}-[r1:`#{self._type}`]->#{cypher_string(:inbound)}")
     end


**#as_constant**
  

  .. hidden-code-block:: ruby

     def as_constant(given_class)
       case given_class
       when String
         given_class.constantize
       when Symbol
         given_class.to_s.constantize
       else
         given_class
       end
     end


**#cypher_label**
  

  .. hidden-code-block:: ruby

     def cypher_label(dir = :outbound)
       target_class = dir == :outbound ? as_constant(_from_class) : as_constant(_to_class)
       ":`#{target_class.mapped_label_name}`)"
     end


**#cypher_string**
  

  .. hidden-code-block:: ruby

     def cypher_string(dir = :outbound)
       case dir
       when :outbound
         identifier = '(n1'
         identifier + (_from_class == :any ? ')' : cypher_label(:outbound))
       when :inbound
         identifier = '(n2'
         identifier + (_to_class == :any ? ')' : cypher_label(:inbound))
       end
     end


**#find**
  Returns the object with the specified neo4j id.

  .. hidden-code-block:: ruby

     def find(id, session = self.neo4j_session)
       fail "Unknown argument #{id.class} in find method (expected String or Integer)" if !(id.is_a?(String) || id.is_a?(Integer))
       find_by_id(id, session)
     end


**#find_by_id**
  Loads the relationship using its neo_id.

  .. hidden-code-block:: ruby

     def find_by_id(key, session = Neo4j::Session.current!)
       session.query.match('()-[r]-()').where('ID(r)' => key.to_i).limit(1).return(:r).first.r
     end


**#first**
  

  .. hidden-code-block:: ruby

     def first
       all_query.limit(1).order('ID(r1)').pluck(:r1).first
     end


**#last**
  

  .. hidden-code-block:: ruby

     def last
       all_query.limit(1).order('ID(r1) DESC').pluck(:r1).first
     end


**#where**
  Performs a very basic match on the relationship.
  This is not executed lazily, it will immediately return matching objects.
  To use a string, prefix the property with "r1"

  .. hidden-code-block:: ruby

     def where(args = {})
       where_query.where(where_string(args)).pluck(:r1)
     end


**#where_query**
  

  .. hidden-code-block:: ruby

     def where_query
       Neo4j::Session.query.match("#{cypher_string(:outbound)}-[r1:`#{self._type}`]->#{cypher_string(:inbound)}")
     end


**#where_string**
  

  .. hidden-code-block:: ruby

     def where_string(args)
       case args
       when Hash
         args.map { |k, v| v.is_a?(Integer) ? "r1.#{k} = #{v}" : "r1.#{k} = '#{v}'" }.join(', ')
       else
         args
       end
     end





