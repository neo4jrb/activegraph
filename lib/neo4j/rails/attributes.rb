module Neo4j
  module Rails
    # This module handles the getting, setting and updating of attributes or properties
    # in a Railsy way.  This typically means not writing anything to the DB until the
    # object is saved (after validation).
    #
    # Externally, when we talk about properties (e.g. #property?, #property_names, #properties),
    # we mean all of the stored properties for this object include the 'hidden' props
    # with underscores at the beginning such as _neo_id and _classname.  When we talk
    # about attributes, we mean all the properties apart from those hidden ones.
    module Attributes
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Dirty # track changes to attributes
        include ActiveModel::MassAssignmentSecurity # handle attribute hash assignment

        class_inheritable_accessor :attribute_defaults
        self.attribute_defaults ||= {}

        # save the original [] and []= to use as read/write to Neo4j
        alias_method :read_attribute, :[]
        alias_method :write_attribute, :[]=

        # wrap the read/write in type conversion
        alias_method_chain :read_local_property, :type_conversion
        alias_method_chain :write_local_property, :type_conversion

        # whenever we refer to [] or []=. use our local properties store
        alias_method :[], :read_local_property
        alias_method :[]=, :write_local_property
      end

      # The behaviour of []= changes with a Rails Model, where nothing gets written
      # to Neo4j until the object is saved, during which time all the validations
      # and callbacks are run to ensure correctness
      def write_local_property(key, value)
        key_s = key.to_s
        if !@properties.has_key?(key_s) || @properties[key_s] != value
          attribute_will_change!(key_s)
          @properties[key_s] = value.nil? ? attribute_defaults[key_s] : value
        end
        value
      end

      # Returns the locally stored value for the key or retrieves the value from
      # the DB if we don't have one
      def read_local_property(key)
        key = key.to_s
        if @properties.has_key?(key)
          @properties[key]
        else
          @properties[key] = (persisted? && _java_entity.has_property?(key)) ? read_attribute(key) : attribute_defaults[key]
        end
      end

      # Mass-assign attributes.  Stops any protected attributes from being assigned.
      def attributes=(attributes, guard_protected_attributes = true)
        attributes = sanitize_for_mass_assignment(attributes) if guard_protected_attributes

        multi_parameter_attributes = []
        attributes.each do |k, v|
          if k.to_s.include?("(")
            multi_parameter_attributes << [ k, v ]
          else
            respond_to?("#{k}=") ? send("#{k}=", v) : self[k] = v
          end
        end

        assign_multiparameter_attributes(multi_parameter_attributes)
      end

      # Instantiates objects for all attribute classes that needs more than one constructor parameter. This is done
      # by calling new on the column type or aggregation type (through composed_of) object with these parameters.
      # So having the pairs written_on(1) = "2004", written_on(2) = "6", written_on(3) = "24", will instantiate
      # written_on (a date type) with Date.new("2004", "6", "24"). You can also specify a typecast character in the
      # parentheses to have the parameters typecasted before they're used in the constructor. Use i for Fixnum,
      # f for Float, s for String, and a for Array. If all the values for a given attribute are empty, the
      # attribute will be set to nil.
      def assign_multiparameter_attributes(pairs)
        execute_callstack_for_multiparameter_attributes(
          extract_callstack_for_multiparameter_attributes(pairs)
        )
      end

      def execute_callstack_for_multiparameter_attributes(callstack)
        errors = []
        callstack.each do |name, values_with_empty_parameters|
          begin
            # (self.class.reflect_on_aggregation(name.to_sym) || column_for_attribute(name)).klass
            decl_type = self.class._decl_props[name.to_sym][:type]
            raise "Not a multiparameter attribute, missing :type on property #{name} for #{self.class}" unless decl_type

            # in order to allow a date to be set without a year, we must keep the empty values.
            values = values_with_empty_parameters.reject { |v| v.nil? }

            if values.empty?
              send(name + "=", nil)
            else

              #TODO: Consider extracting hardcoded assignments into "Binders"
              value = if Neo4j::TypeConverters::TimeConverter.convert?(decl_type)
                instantiate_time_object(name, values)
              elsif Neo4j::TypeConverters::DateConverter.convert?(decl_type)
                begin
                  values = values_with_empty_parameters.collect do |v| v.nil? ? 1 : v end
                  Date.new(*values)
                rescue ArgumentError => ex # if Date.new raises an exception on an invalid date
                  instantiate_time_object(name, values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
                end
              elsif Neo4j::TypeConverters::DateTimeConverter.convert?(decl_type)
                DateTime.new(*values)
              else
                raise "Unknown type #{decl_type}"
              end

              send(name + "=", value)
            end
          rescue Exception => ex
            raise "error on assignment #{values.inspect} to #{name}, ex: #{ex}"
          end
        end
        unless errors.empty?
          raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
        end
      end

      def instantiate_time_object(name, values)
#        if self.class.send(:create_time_zone_conversion_attribute?, name, column_for_attribute(name))
#          Time.zone.local(*values)
#        else
          Time.time_with_datetime_fallback(self.class.default_timezone, *values)
#        end
      end

      def extract_callstack_for_multiparameter_attributes(pairs)
        attributes = { }

        for pair in pairs
          multiparameter_name, value = pair
          attribute_name = multiparameter_name.split("(").first
          attributes[attribute_name] = [] unless attributes.include?(attribute_name)

          parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
          attributes[attribute_name] << [ find_parameter_position(multiparameter_name), parameter_value ]
        end

        attributes.each { |name, values| attributes[name] = values.sort_by{ |v| v.first }.collect { |v| v.last } }
      end


      def type_cast_attribute_value(multiparameter_name, value)
        multiparameter_name =~ /\([0-9]*([if])\)/ ? value.send("to_" + $1) : value
      end

      def find_parameter_position(multiparameter_name)
        multiparameter_name.scan(/\(([0-9]*).*\)/).first.first
      end

      # Tracks the current changes and clears the changed attributes hash.  Called
      # after saving the object.
      def clear_changes
        @previously_changed = changes
        @changed_attributes.clear
      end

      # Return the properties from the Neo4j Node, merged with those that haven't
      # yet been saved
      def props
        ret = {}
        property_names.each do |property_name|
          ret[property_name] = respond_to?(property_name) ? send(property_name) : send(:[], property_name)
        end
        ret
      end

      # Return all the attributes for this model as a hash attr => value.  Doesn't
      # include properties that start with <tt>_</tt>.
      def attributes
        ret = {}
        attribute_names.each do |attribute_name|
          ret[attribute_name] = self._decl_props[attribute_name.to_sym] ? send(attribute_name) :  send(:[], attribute_name)
        end
        ret
      end

      # Known properties are either in the @properties, the declared
      # attributes or the property keys for the persisted node.
      def property_names
        # initialize @properties if needed since
        # we can ask property names before the object is initialized (active_support initialize callbacks, respond_to?)
        @properties ||= {}
        keys = @properties.keys + self.class._decl_props.keys.map { |k| k.to_s }
        keys += _java_entity.property_keys.to_a if persisted?
        keys.flatten.uniq
      end

      # Known attributes are either in the @properties, the declared
      # attributes or the property keys for the persisted node.  Any attributes
      # that start with <tt>_</tt> are rejected
      def attribute_names
        property_names.reject { |property_name| _invalid_attribute_name?(property_name) }
      end

      def _invalid_attribute_name?(attr_name)
        attr_name.to_s[0] == ?_ && !self.class._decl_props.include?(attr_name.to_sym)
      end

      # Known properties are either in the @properties, the declared
      # properties or the property keys for the persisted node
      def property?(name)
        return false unless @properties
        @properties.has_key?(name) ||
            self.class._decl_props.has_key?(name) ||
            persisted? && super
      end

      def property_changed?
        return !@properties.empty? unless persisted?
        !!@properties.keys.find{|k| self._java_node.getProperty(k.to_s) != @properties[k] }
      end

      # Return true if method_name is the name of an appropriate attribute
      # method
      def attribute?(name)
        name[0] != ?_ && property?(name)
      end

      def _classname
        self.class.to_s
      end

      def _classname=(value)
        write_local_property_without_type_conversion("_classname",value)
      end


      # TODO THIS IS ONLY NEEDED IN ACTIVEMODEL < 3.2, ?
      # To get ActiveModel::Dirty to work, we need to be able to call undeclared
      # properties as though they have get methods
      def method_missing(method_id, *args, &block)
        method_name = method_id.to_s
        if property?(method_name)
          self[method_name]
        else
          super
        end
      end

      # Wrap the getter in a conversion from Java to Ruby
      def read_local_property_with_type_conversion(property)
        Neo4j::TypeConverters.to_ruby(self.class, property, read_local_property_without_type_conversion(property))
      end

      # Wrap the setter in a conversion from Ruby to Java
      def write_local_property_with_type_conversion(property, value)
        @properties_before_type_cast[property.to_sym]=value if self.class._decl_props.has_key? property.to_sym
        write_local_property_without_type_conversion(property, Neo4j::TypeConverters.to_java(self.class, property, value))
      end
    end
  end
end
