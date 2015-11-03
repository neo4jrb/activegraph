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
  

  .. code-block:: ruby

     def args(var, rel_var)
       @arg.respond_to?(:call) ? @arg.call(var, rel_var) : [@arg, @args].flatten
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link#clause`:

**#clause**
  Returns the value of attribute clause

  .. code-block:: ruby

     def clause
       @clause
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.converted_value`:

**.converted_value**
  

  .. code-block:: ruby

     def converted_value(model, key, value)
       model.declared_properties.value_for_where(key, value)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_arg`:

**.for_arg**
  

  .. code-block:: ruby

     def for_arg(model, clause, arg, *args)
       default = [Link.new(clause, arg, *args)]
     
       Link.for_clause(clause, arg, model, *args) || default
     rescue NoMethodError
       default
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_args`:

**.for_args**
  

  .. code-block:: ruby

     def for_args(model, clause, args, association = nil)
       if [:where, :where_not].include?(clause) && args[0].is_a?(String) # Better way?
         [for_arg(model, clause, args[0], *args[1..-1])]
       elsif clause == :rel_where
         args.map { |arg| for_arg(model, clause, arg, association) }
       else
         args.map { |arg| for_arg(model, clause, arg) }
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_association`:

**.for_association**
  

  .. code-block:: ruby

     def for_association(name, value, n_string, model)
       neo_id = value.try(:neo_id) || value
       fail ArgumentError, "Invalid value for '#{name}' condition" if not neo_id.is_a?(Integer)
     
       [
         new(:match, ->(v, _) { "#{v}#{model.associations[name].arrow_cypher}(#{n_string})" }),
         new(:where, ->(_, _) { {"ID(#{n_string})" => neo_id.to_i} })
       ]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_clause`:

**.for_clause**
  

  .. code-block:: ruby

     def for_clause(clause, arg, model, *args)
       method_to_call = "for_#{clause}_clause"
     
       send(method_to_call, arg, model, *args)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_node_where_clause`:

**.for_node_where_clause**
  

  .. code-block:: ruby

     def for_where_clause(arg, model, *args)
       node_num = 1
       result = []
       if arg.is_a?(Hash)
         arg.each do |key, value|
           if model && model.association?(key)
             result += for_association(key, value, "n#{node_num}", model)
             node_num += 1
           else
             result << new_for_key_and_value(model, key, value)
           end
         end
       elsif arg.is_a?(String)
         result << new(:where, arg, args)
       end
       result
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_order_clause`:

**.for_order_clause**
  

  .. code-block:: ruby

     def for_order_clause(arg, _)
       [new(:order, ->(v, _) { arg.is_a?(String) ? arg : {v => arg} })]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_rel_order_clause`:

**.for_rel_order_clause**
  

  .. code-block:: ruby

     def for_rel_order_clause(arg, _)
       [new(:order, ->(_, v) { arg.is_a?(String) ? arg : {v => arg} })]
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_rel_where_clause`:

**.for_rel_where_clause**
  We don't accept strings here. If you want to use a string, just use where.

  .. code-block:: ruby

     def for_rel_where_clause(arg, _, association)
       arg.each_with_object([]) do |(key, value), result|
         rel_class = association.relationship_class if association.relationship_class
         val =  rel_class ? converted_value(rel_class, key, value) : value
         result << new(:where, ->(_, rel_var) { {rel_var => {key => val}} })
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_where_clause`:

**.for_where_clause**
  

  .. code-block:: ruby

     def for_where_clause(arg, model, *args)
       node_num = 1
       result = []
       if arg.is_a?(Hash)
         arg.each do |key, value|
           if model && model.association?(key)
             result += for_association(key, value, "n#{node_num}", model)
             node_num += 1
           else
             result << new_for_key_and_value(model, key, value)
           end
         end
       elsif arg.is_a?(String)
         result << new(:where, arg, args)
       end
       result
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.for_where_not_clause`:

**.for_where_not_clause**
  

  .. code-block:: ruby

     def for_where_not_clause(*args)
       for_where_clause(*args).each do |link|
         link.instance_variable_set('@clause', :where_not)
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(clause, arg, args = [])
       @clause = clause
       @arg = arg
       @args = args
     end



.. _`Neo4j/ActiveNode/Query/QueryProxy/Link.new_for_key_and_value`:

**.new_for_key_and_value**
  

  .. code-block:: ruby

     def new_for_key_and_value(model, key, value)
       key = (key.to_sym == :id ? model.id_property_name : key)
     
       val = if !model
               value
             elsif key == model.id_property_name && value.is_a?(Neo4j::ActiveNode)
               value.id
             else
               converted_value(model, key, value)
             end
     
       new(:where, ->(v, _) { {v => {key => val}} })
     end





