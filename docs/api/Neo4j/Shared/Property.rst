Property
========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   Property/UndefinedPropertyError

   Property/MultiparameterAssignmentError

   Property/IllegalPropertyError

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   Property/ClassMethods




Constants
---------



  * ILLEGAL_PROPS



Files
-----



  * `lib/neo4j/shared/property.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/property.rb#L2>`_





Methods
-------


**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end


**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
       # keys = self.class.default_properties.keys
       # _persisted_obj.props.reject{|key| !keys.include?(key)}
     end


**#default_properties=**
  

  .. hidden-code-block:: ruby

     def default_properties=(properties)
       keys = self.class.default_properties.keys
       @default_properties = properties.select { |key| keys.include?(key) }
     end


**#default_property**
  

  .. hidden-code-block:: ruby

     def default_property(key)
       default_properties[key.to_sym]
     end


**#extract_writer_methods!**
  

  .. hidden-code-block:: ruby

     def extract_writer_methods!(attributes)
       {}.tap do |writer_method_props|
         attributes.each_key do |key|
           writer_method_props[key] = attributes.delete(key) if self.respond_to?("#{key}=")
         end
       end
     end


**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(attributes = {}, options = {})
       attributes = process_attributes(attributes)
       @relationship_props = self.class.extract_association_attributes!(attributes)
       writer_method_props = extract_writer_methods!(attributes)
       validate_attributes!(attributes)
       send_props(writer_method_props) unless writer_method_props.nil?
     
       @_persisted_obj = nil
     
       super(attributes, options)
     end


**#instantiate_object**
  

  .. hidden-code-block:: ruby

     def instantiate_object(field, values_with_empty_parameters)
       return nil if values_with_empty_parameters.all?(&:nil?)
       values = values_with_empty_parameters.collect { |v| v.nil? ? 1 : v }
       klass = field[:type]
       klass ? klass.new(*values) : values
     end


**#magic_typecast_properties**
  

  .. hidden-code-block:: ruby

     def magic_typecast_properties
       self.class.magic_typecast_properties
     end


**#process_attributes**
  Gives support for Rails date_select, datetime_select, time_select helpers.

  .. hidden-code-block:: ruby

     def process_attributes(attributes = nil)
       multi_parameter_attributes = {}
       new_attributes = {}
       attributes.each_pair do |key, value|
         if match = key.match(/\A([^\(]+)\((\d+)([if])\)$/)
           found_key = match[1]
           index = match[2].to_i
           (multi_parameter_attributes[found_key] ||= {})[index] = value.empty? ? nil : value.send("to_#{$3}")
         else
           new_attributes[key] = value
         end
       end
     
       multi_parameter_attributes.empty? ? new_attributes : process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
     end


**#process_multiparameter_attributes**
  

  .. hidden-code-block:: ruby

     def process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
       multi_parameter_attributes.each_with_object(new_attributes) do |(key, values), attributes|
         values = (values.keys.min..values.keys.max).map { |i| values[i] }
     
         if (field = self.class.attributes[key.to_sym]).nil?
           fail MultiparameterAssignmentError, "error on assignment #{values.inspect} to #{key}"
         end
     
         attributes[key] = instantiate_object(field, values)
       end
     end


**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


**#send_props**
  

  .. hidden-code-block:: ruby

     def send_props(hash)
       hash.each { |key, value| self.send("#{key}=", value) }
     end


**#validate_attributes!**
  Changes attributes hash to remove relationship keys
  Raises an error if there are any keys left which haven't been defined as properties on the model

  .. hidden-code-block:: ruby

     def validate_attributes!(attributes)
       invalid_properties = attributes.keys.map(&:to_s) - self.attributes.keys
       fail UndefinedPropertyError, "Undefined properties: #{invalid_properties.join(',')}" if invalid_properties.size > 0
     end





