Link
====




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query/query_proxy_link.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_link.rb#L5>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link#args`:

**#args**
  

  .. hidden-code-block:: ruby

     def args(var, rel_var)
       @arg.respond_to?(:call) ? @arg.call(var, rel_var) : @arg
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link#clause`:

**#clause**
  Returns the value of attribute clause

  .. hidden-code-block:: ruby

     def clause
       @clause
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_association`:

**.for_association**
  

  .. hidden-code-block:: ruby

     def for_association(name, value, n_string, model)
       neo_id = value.try(:neo_id) || value
       fail ArgumentError, "Invalid value for '#{name}' condition" if not neo_id.is_a?(Integer)
     
       dir = model.associations[name].direction
     
       arrow = dir == :out ? '-->' : '<--'
       [
         new(:match, ->(v, _) { "#{v}#{arrow}(#{n_string})" }),
         new(:where, ->(_, _) { {"ID(#{n_string})" => neo_id.to_i} })
       ]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_clause`:

**.for_clause**
  

  .. hidden-code-block:: ruby

     def for_clause(clause, arg, model)
       method_to_call = "for_#{clause}_clause"
     
       send(method_to_call, arg, model)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_node_where_clause`:

**.for_node_where_clause**
  

  .. hidden-code-block:: ruby

     def for_where_clause(arg, model)
       node_num = 1
       result = []
       if arg.is_a?(Hash)
         arg.each do |key, value|
           if model && model.association?(key)
             result += for_association(key, value, "n#{node_num}", model)
     
             node_num += 1
           else
             result << new(:where, ->(v, _) { {v => {key => value}} })
           end
         end
       elsif arg.is_a?(String)
         result << new(:where, arg)
       end
       result
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_order_clause`:

**.for_order_clause**
  

  .. hidden-code-block:: ruby

     def for_order_clause(arg, _)
       [new(:order, ->(v, _) { arg.is_a?(String) ? arg : {v => arg} })]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_rel_where_clause`:

**.for_rel_where_clause**
  We don't accept strings here. If you want to use a string, just use where.

  .. hidden-code-block:: ruby

     def for_rel_where_clause(arg, _)
       arg.each_with_object([]) do |(key, value), result|
         result << new(:where, ->(_, rel_var) { {rel_var => {key => value}} })
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_where_clause`:

**.for_where_clause**
  

  .. hidden-code-block:: ruby

     def for_where_clause(arg, model)
       node_num = 1
       result = []
       if arg.is_a?(Hash)
         arg.each do |key, value|
           if model && model.association?(key)
             result += for_association(key, value, "n#{node_num}", model)
     
             node_num += 1
           else
             result << new(:where, ->(v, _) { {v => {key => value}} })
           end
         end
       elsif arg.is_a?(String)
         result << new(:where, arg)
       end
       result
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link#initialize`:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(clause, arg)
       @clause = clause
       @arg = arg
     end





