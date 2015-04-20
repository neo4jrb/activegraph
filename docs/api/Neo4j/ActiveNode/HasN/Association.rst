Association
===========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/has_n/association.rb:6 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association.rb#L6>`_





Methods
-------



.. _`Neo4j/ActiveNode/HasN/Association#add_destroy_callbacks`:

**#add_destroy_callbacks**
  

  .. hidden-code-block:: ruby

     def add_destroy_callbacks(model)
       return if dependent.nil?
     
       model.before_destroy(&method("dependent_#{dependent}_callback"))
     rescue NameError
       raise "Unknown dependent option #{dependent}"
     end



.. _`Neo4j/ActiveNode/HasN/Association#arrow_cypher`:

**#arrow_cypher**
  Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)

  .. hidden-code-block:: ruby

     def arrow_cypher(var = nil, properties = {}, create = false, reverse = false)
       validate_origin!
       direction_cypher(get_relationship_cypher(var, properties, create), create, reverse)
     end



.. _`Neo4j/ActiveNode/HasN/Association#callback`:

**#callback**
  

  .. hidden-code-block:: ruby

     def callback(type)
       @callbacks[type]
     end



.. _`Neo4j/ActiveNode/HasN/Association#create_method`:

**#create_method**
  

  .. hidden-code-block:: ruby

     def create_method
       unique? ? :create_unique : :create
     end



.. _`Neo4j/ActiveNode/HasN/Association#decorated_rel_type`:

**#decorated_rel_type**
  

  .. hidden-code-block:: ruby

     def decorated_rel_type(type)
       @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
     end



.. _`Neo4j/ActiveNode/HasN/Association#dependent`:

**#dependent**
  Returns the value of attribute dependent

  .. hidden-code-block:: ruby

     def dependent
       @dependent
     end



.. _`Neo4j/ActiveNode/HasN/Association#direction`:

**#direction**
  Returns the value of attribute direction

  .. hidden-code-block:: ruby

     def direction
       @direction
     end



.. _`Neo4j/ActiveNode/HasN/Association#initialize`:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(type, direction, name, options = {})
       validate_init_arguments(type, direction, options)
       @type = type.to_sym
       @name = name
       @direction = direction.to_sym
       @target_class_name_from_name = name.to_s.classify
       apply_vars_from_options(options)
     end



.. _`Neo4j/ActiveNode/HasN/Association#inject_classname`:

**#inject_classname**
  

  .. hidden-code-block:: ruby

     def inject_classname(properties)
       return properties unless @relationship_class
       properties[Neo4j::Config.class_name_property] = relationship_class_name if relationship_clazz.cached_class?(true)
       properties
     end



.. _`Neo4j/ActiveNode/HasN/Association#name`:

**#name**
  Returns the value of attribute name

  .. hidden-code-block:: ruby

     def name
       @name
     end



.. _`Neo4j/ActiveNode/HasN/Association#perform_callback`:

**#perform_callback**
  

  .. hidden-code-block:: ruby

     def perform_callback(caller, other_node, type)
       return if callback(type).nil?
       caller.send(callback(type), other_node)
     end



.. _`Neo4j/ActiveNode/HasN/Association#relationship`:

**#relationship**
  Returns the value of attribute relationship

  .. hidden-code-block:: ruby

     def relationship
       @relationship
     end



.. _`Neo4j/ActiveNode/HasN/Association#relationship_class`:

**#relationship_class**
  Returns the value of attribute relationship_class

  .. hidden-code-block:: ruby

     def relationship_class
       @relationship_class
     end



.. _`Neo4j/ActiveNode/HasN/Association#relationship_class_name`:

**#relationship_class_name**
  

  .. hidden-code-block:: ruby

     def relationship_class_name
       @relationship_class_name ||= @relationship_class.respond_to?(:constantize) ? @relationship_class : @relationship_class.name
     end



.. _`Neo4j/ActiveNode/HasN/Association#relationship_class_type`:

**#relationship_class_type**
  

  .. hidden-code-block:: ruby

     def relationship_class_type
       @relationship_class = @relationship_class.constantize if @relationship_class.class == String || @relationship_class == Symbol
       @relationship_class._type
     end



.. _`Neo4j/ActiveNode/HasN/Association#relationship_clazz`:

**#relationship_clazz**
  

  .. hidden-code-block:: ruby

     def relationship_clazz
       @relationship_clazz ||= if @relationship_class.is_a?(String)
                                 @relationship_class.constantize
                               elsif @relationship_class.is_a?(Symbol)
                                 @relationship_class.to_s.constantize
                               else
                                 @relationship_class
                               end
     end



.. _`Neo4j/ActiveNode/HasN/Association#relationship_type`:

**#relationship_type**
  

  .. hidden-code-block:: ruby

     def relationship_type(create = false)
       case
       when @relationship_class
         relationship_class_type
       when @relationship_type
         @relationship_type
       when @origin
         origin_type
       else
         (create || exceptional_target_class?) && decorated_rel_type(@name)
       end
     end



.. _`Neo4j/ActiveNode/HasN/Association#target_class`:

**#target_class**
  

  .. hidden-code-block:: ruby

     def target_class
       return @target_class if @target_class
     
       @target_class = target_class_names[0].constantize if target_class_names && target_class_names.size == 1
     rescue NameError
       raise ArgumentError, "Could not find `#{@target_class}` class and no :model_class specified"
     end



.. _`Neo4j/ActiveNode/HasN/Association#target_class_names`:

**#target_class_names**
  

  .. hidden-code-block:: ruby

     def target_class_names
       @target_class_names ||= if @target_class_option.is_a?(Array)
                                 @target_class_option.map(&:to_s)
                               elsif @target_class_option
                                 [@target_class_option.to_s]
                               end
     end



.. _`Neo4j/ActiveNode/HasN/Association#target_class_option`:

**#target_class_option**
  

  .. hidden-code-block:: ruby

     def target_class_option(model_class)
       case model_class
       when nil
         if @target_class_name_from_name
           "::#{@target_class_name_from_name}"
         else
           @target_class_name_from_name
         end
       when Array
         model_class.map { |sub_model_class| target_class_option(sub_model_class) }
       when false
         false
       else
         "::#{model_class}"
       end
     end



.. _`Neo4j/ActiveNode/HasN/Association#target_classes_or_nil`:

**#target_classes_or_nil**
  

  .. hidden-code-block:: ruby

     def target_classes_or_nil
       @target_classes_or_nil ||= if target_class_names
                                    target_class_names.map(&:constantize).select do |constant|
                                      constant.ancestors.include?(::Neo4j::ActiveNode)
                                    end
                                  end
     end



.. _`Neo4j/ActiveNode/HasN/Association#type`:

**#type**
  Returns the value of attribute type

  .. hidden-code-block:: ruby

     def type
       @type
     end



.. _`Neo4j/ActiveNode/HasN/Association#unique?`:

**#unique?**
  

  .. hidden-code-block:: ruby

     def unique?
       @origin ? origin_association.unique? : !!@unique
     end



.. _`Neo4j/ActiveNode/HasN/Association#validate_dependent`:

**#validate_dependent**
  

  .. hidden-code-block:: ruby

     def validate_dependent(value)
       fail ArgumentError, "Invalid dependent value: #{value.inspect}" if not valid_dependent_value?(value)
     end





