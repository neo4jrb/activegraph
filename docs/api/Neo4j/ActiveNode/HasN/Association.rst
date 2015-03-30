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


**#add_destroy_callbacks**
  

  .. hidden-code-block:: ruby

     def add_destroy_callbacks(model)
       return if dependent.nil?
     
       model.before_destroy(&method("dependent_#{dependent}_callback"))
     rescue NameError
       raise "Unknown dependent option #{dependent}"
     end


**#apply_vars_from_options**
  

  .. hidden-code-block:: ruby

     def apply_vars_from_options(options)
       @target_class_option = target_class_option(options)
       @callbacks = {before: options[:before], after: options[:after]}
       @origin = options[:origin] && options[:origin].to_sym
       @relationship_class = options[:rel_class]
       @relationship_type  = options[:type] && options[:type].to_sym
       @dependent = options[:dependent].try(:to_sym)
       @unique = options[:unique]
     end


**#arrow_cypher**
  Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)

  .. hidden-code-block:: ruby

     def arrow_cypher(var = nil, properties = {}, create = false, reverse = false)
       validate_origin!
       direction_cypher(get_relationship_cypher(var, properties, create), create, reverse)
     end


**#base_declaration**
  Return basic details about association as declared in the model

  .. hidden-code-block:: ruby

     def base_declaration
       "#{type} #{direction.inspect}, #{name.inspect}"
     end


**#callback**
  

  .. hidden-code-block:: ruby

     def callback(type)
       @callbacks[type]
     end


**#check_valid_type_and_dir**
  

  .. hidden-code-block:: ruby

     def check_valid_type_and_dir(type, direction)
       fail ArgumentError, "Invalid association type: #{type.inspect} (valid value: :has_many and :has_one)" if ![:has_many, :has_one].include?(type.to_sym)
       fail ArgumentError, "Invalid direction: #{direction.inspect} (valid value: :out, :in, and :both)" if ![:out, :in, :both].include?(direction.to_sym)
     end


**#decorated_rel_type**
  

  .. hidden-code-block:: ruby

     def decorated_rel_type(type)
       @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
     end


**#dependent**
  Returns the value of attribute dependent

  .. hidden-code-block:: ruby

     def dependent
       @dependent
     end


**#dependent_delete_callback**
  Callback methods

  .. hidden-code-block:: ruby

     def dependent_delete_callback(object)
       object.association_query_proxy(name).delete_all
     end


**#dependent_delete_orphans_callback**
  

  .. hidden-code-block:: ruby

     def dependent_delete_orphans_callback(object)
       object.as(:self).unique_nodes(self, :self, :n, :other_rel).query.delete(:n, :other_rel).exec
     end


**#dependent_destroy_callback**
  

  .. hidden-code-block:: ruby

     def dependent_destroy_callback(object)
       object.association_query_proxy(name).each_for_destruction(object, &:destroy)
     end


**#dependent_destroy_orphans_callback**
  

  .. hidden-code-block:: ruby

     def dependent_destroy_orphans_callback(object)
       object.as(:self).unique_nodes(self, :self, :n, :other_rel).each_for_destruction(object, &:destroy)
     end


**#direction**
  Returns the value of attribute direction

  .. hidden-code-block:: ruby

     def direction
       @direction
     end


**#direction_cypher**
  

  .. hidden-code-block:: ruby

     def direction_cypher(relationship_cypher, create, reverse = false)
       case get_direction(create, reverse)
       when :out
         "-#{relationship_cypher}->"
       when :in
         "<-#{relationship_cypher}-"
       when :both
         "-#{relationship_cypher}-"
       end
     end


**#exceptional_target_class?**
  Determine if model class as derived from the association name would be different than the one specified via the model_class key

  .. hidden-code-block:: ruby

     def exceptional_target_class?
       # TODO: Exceptional if target_class.nil?? (when model_class false)
     
       target_class && target_class.name != @target_class_name_from_name
     end


**#get_direction**
  

  .. hidden-code-block:: ruby

     def get_direction(create, reverse = false)
       dir = (create && @direction == :both) ? :out : @direction
       if reverse
         case dir
         when :in then :out
         when :out then :in
         else :both
         end
       else
         dir
       end
     end


**#get_properties_string**
  

  .. hidden-code-block:: ruby

     def get_properties_string(properties)
       p = properties.map do |key, value|
         "#{key}: #{value.inspect}"
       end.join(', ')
       p.size == 0 ? '' : " {#{p}}"
     end


**#get_relationship_cypher**
  

  .. hidden-code-block:: ruby

     def get_relationship_cypher(var, properties, create)
       relationship_type = relationship_type(create)
       relationship_name_cypher = ":`#{relationship_type}`" if relationship_type
       properties_string = get_properties_string(properties)
     
       "[#{var}#{relationship_name_cypher}#{properties_string}]"
     end


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


**#inject_classname**
  

  .. hidden-code-block:: ruby

     def inject_classname(properties)
       return properties unless @relationship_class
       properties[Neo4j::Config.class_name_property] = relationship_class_name if relationship_clazz.cached_class?(true)
       properties
     end


**#name**
  Returns the value of attribute name

  .. hidden-code-block:: ruby

     def name
       @name
     end


**#origin_association**
  

  .. hidden-code-block:: ruby

     def origin_association
       target_class.associations[@origin]
     end


**#origin_type**
  

  .. hidden-code-block:: ruby

     def origin_type
       origin_association.relationship_type
     end


**#perform_callback**
  

  .. hidden-code-block:: ruby

     def perform_callback(caller, other_node, type)
       return if callback(type).nil?
       caller.send(callback(type), other_node)
     end


**#relationship**
  Returns the value of attribute relationship

  .. hidden-code-block:: ruby

     def relationship
       @relationship
     end


**#relationship_class**
  Returns the value of attribute relationship_class

  .. hidden-code-block:: ruby

     def relationship_class
       @relationship_class
     end


**#relationship_class_name**
  

  .. hidden-code-block:: ruby

     def relationship_class_name
       @relationship_class_name ||= @relationship_class.respond_to?(:constantize) ? @relationship_class : @relationship_class.name
     end


**#relationship_class_type**
  

  .. hidden-code-block:: ruby

     def relationship_class_type
       @relationship_class = @relationship_class.constantize if @relationship_class.class == String || @relationship_class == Symbol
       @relationship_class._type
     end


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


**#target_class**
  

  .. hidden-code-block:: ruby

     def target_class
       return @target_class if @target_class
     
       @target_class = target_class_name.constantize if target_class_name
     rescue NameError
       raise ArgumentError, "Could not find `#{@target_class}` class and no :model_class specified"
     end


**#target_class_name**
  

  .. hidden-code-block:: ruby

     def target_class_name
       @target_class_name ||= @target_class_option.to_s if @target_class_option
     end


**#target_class_option**
  

  .. hidden-code-block:: ruby

     def target_class_option(options)
       if options[:model_class].nil?
         if @target_class_name_from_name
           "::#{@target_class_name_from_name}"
         else
           @target_class_name_from_name
         end
       elsif options[:model_class] == false
         false
       else
         "::#{options[:model_class]}"
       end
     end


**#target_class_or_nil**
  

  .. hidden-code-block:: ruby

     def target_class_or_nil
       @target_class_or_nil ||= target_class_name ? target_class_name.constantize : nil
     end


**#type**
  Returns the value of attribute type

  .. hidden-code-block:: ruby

     def type
       @type
     end


**#unique?**
  

  .. hidden-code-block:: ruby

     def unique?
       @origin ? origin_association.unique? : !!@unique
     end


**#valid_dependent_value?**
  

  .. hidden-code-block:: ruby

     def valid_dependent_value?(value)
       return true if value.nil?
     
       self.respond_to?("dependent_#{value}_callback", true)
     end


**#validate_dependent**
  

  .. hidden-code-block:: ruby

     def validate_dependent(value)
       fail ArgumentError, "Invalid dependent value: #{value.inspect}" if not valid_dependent_value?(value)
     end


**#validate_init_arguments**
  

  .. hidden-code-block:: ruby

     def validate_init_arguments(type, direction, options)
       validate_option_combinations(options)
       validate_dependent(options[:dependent].try(:to_sym))
       check_valid_type_and_dir(type, direction)
     end


**#validate_option_combinations**
  

  .. hidden-code-block:: ruby

     def validate_option_combinations(options)
       [[:type, :origin],
        [:type, :rel_class],
        [:origin, :rel_class]].each do |key1, key2|
         if options[key1] && options[key2]
           fail ArgumentError, "Cannot specify both :#{key1} and :#{key2} (#{base_declaration})"
         end
       end
     end


**#validate_origin!**
  

  .. hidden-code-block:: ruby

     def validate_origin!
       return if not @origin
     
       association = origin_association
     
       message = case
                 when !target_class
                   'Cannot use :origin without a model_class (implied or explicit)'
                 when !association
                   "Origin `#{@origin.inspect}` association not found for #{target_class} (specified in #{base_declaration})"
                 when @direction == association.direction
                   "Origin `#{@origin.inspect}` (specified in #{base_declaration}) has same direction `#{@direction}`)"
                 end
     
       fail ArgumentError, message if message
     end





