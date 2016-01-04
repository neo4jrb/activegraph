ClassArguments
==============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------



  * INVALID_CLASS_ARGUMENT_ERROR



Files
-----



  * `lib/neo4j/class_arguments.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/class_arguments.rb#L2>`_





Methods
-------



.. _`Neo4j/ClassArguments.active_node_model?`:

**.active_node_model?**
  

  .. code-block:: ruby

     def active_node_model?(class_constant)
       class_constant.included_modules.include?(Neo4j::ActiveNode)
     end



.. _`Neo4j/ClassArguments.constantize_argument`:

**.constantize_argument**
  

  .. code-block:: ruby

     def constantize_argument(class_argument)
       case class_argument
       when 'any', :any, false, nil
         nil
       when Array
         class_argument.map(&method(:constantize_argument))
       else
         class_argument.to_s.constantize.tap do |class_constant|
           if !active_node_model?(class_constant)
             fail ArgumentError, "#{class_constant} is not an ActiveNode model"
           end
         end
       end
     rescue NameError
       raise ArgumentError, "Could not find class: #{class_argument}"
     end



.. _`Neo4j/ClassArguments.valid_argument?`:

**.valid_argument?**
  

  .. code-block:: ruby

     def valid_argument?(class_argument)
       [NilClass, String, Symbol, FalseClass].include?(class_argument.class) ||
         (class_argument.is_a?(Array) && class_argument.all? { |c| [Symbol, String].include?(c.class) })
     end



.. _`Neo4j/ClassArguments.validate_argument!`:

**.validate_argument!**
  

  .. code-block:: ruby

     def validate_argument!(class_argument, context)
       return if valid_argument?(class_argument)
     
       fail ArgumentError, "#{context} #{INVALID_CLASS_ARGUMENT_ERROR} (was #{class_argument.inspect})"
     end





