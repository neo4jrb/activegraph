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
      extend TxMethods

      included do
        include ActiveModel::Dirty # track changes to attributes
        include ActiveModel::MassAssignmentSecurity # handle attribute hash assignment

        class << self
          attr_accessor :attribute_defaults
        end

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

        def self.inherited(sub_klass)
          super
          return if sub_klass.to_s[0..0] == '#' # this is really for anonymous test classes
          setup_neo4j_subclass(sub_klass)
          sub_klass.send(:define_method, :attribute_defaults) do
            self.class.attribute_defaults
          end
          sub_klass.attribute_defaults = self.attribute_defaults.clone
          # Hmm, could not do this from the Finders Mixin Module - should be moved
          sub_klass.rule(:_all, :functions => Neo4j::Wrapper::Rule::Functions::Size.new) if sub_klass.respond_to?(:rule)
        end
      end

      def init_on_create(*)
        self._classname = self.class.to_s
        write_default_attributes
        write_changed_attributes
        clear_changes
      end

      def initialize_attributes(attributes)
        @_properties = {}
        @_properties_before_type_cast={}
        self.attributes = attributes if attributes
      end

      # Mass-assign attributes.  Stops any protected attributes from being assigned.
      def attributes=(attributes, guard_protected_attributes = true)
        attributes = sanitize_for_mass_assignment(attributes) if guard_protected_attributes

        multi_parameter_attributes = []
        attributes.each do |k, v|
          if k.to_s.include?("(")
            multi_parameter_attributes << [k, v]
          else
            respond_to?("#{k}=") ? send("#{k}=", v) : self[k] = v
          end
        end

        assign_multiparameter_attributes(multi_parameter_attributes)
      end

      def attribute_defaults
        self.class.attribute_defaults
      end

      # Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
      # If saving fails because the resource is invalid then false will be returned.
      def update_attributes(attributes)
        self.attributes = attributes
        save
      end
      tx_methods :update_attributes

      # Same as #update_attributes, but raises an exception if saving fails.
      def update_attributes!(attributes)
        self.attributes = attributes
        save!
      end
      tx_methods :update_attributes!

      def reset_attributes
        @_properties = {}
      end



      # Updates a single attribute and saves the record.
      # This is especially useful for boolean flags on existing records. Also note that
      #
      # * Validation is skipped.
      # * Callbacks are invoked.
      # * Updates all the attributes that are dirty in this object.
      #
      def update_attribute(name, value)
        respond_to?("#{name}=") ? send("#{name}=", value) : self[name] = value
        save(:validate => false)
      end

      def hash
        persisted? ? _java_entity.neo_id.hash : super
      end

      def to_param
        persisted? ? neo_id.to_s : nil
      end

      def to_model
        self
      end

      # Returns an Enumerable of all (primary) key attributes
      # or nil if model.persisted? is false
      def to_key
        persisted? ? [id] : nil
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
          ret[attribute_name] = self.class._decl_props[attribute_name.to_sym] ? send(attribute_name) : send(:[], attribute_name)
        end
        ret
      end

      # Known properties are either in the @_properties, the declared
      # attributes or the property keys for the persisted node.
      def property_names
        # initialize @_properties if needed since
        # we can ask property names before the object is initialized (active_support initialize callbacks, respond_to?)
        @_properties ||= {}
        keys = @_properties.keys + self.class._decl_props.keys.map(&:to_s)
        keys += _java_entity.property_keys.to_a if persisted?
        keys.flatten.uniq
      end

      # Known attributes are either in the @_properties, the declared
      # attributes or the property keys for the persisted node.  Any attributes
      # that start with <tt>_</tt> are rejected
      def attribute_names
        property_names.reject { |property_name| _invalid_attribute_name?(property_name) }
      end

      # Known properties are either in the @_properties, the declared
      # properties or the property keys for the persisted node
      def property?(name)
        return false unless @_properties
        @_properties.has_key?(name) ||
            self.class._decl_props.has_key?(name) ||
            persisted? && super
      end

      def property_changed?
        return !@_properties.empty? unless persisted?
        !!@_properties.keys.find { |k| self._java_node[k] != @_properties[k] }
      end

      # Return true if method_name is the name of an appropriate attribute
      # method
      def attribute?(name)
        name[0] != ?_ && property?(name)
      end


      # Wrap the getter in a conversion from Java to Ruby
      def read_local_property_with_type_conversion(property)
        self.class._converter(property).to_ruby(read_local_property_without_type_conversion(property))
      end

      # Wrap the setter in a conversion from Ruby to Java
      def write_local_property_with_type_conversion(property, value)
        @_properties_before_type_cast[property.to_sym]=value if self.class._decl_props.has_key? property.to_sym
        conv_value = self.class._converter(property.to_sym).to_java(value)
        write_local_property_without_type_conversion(property, conv_value)
      end


      # The behaviour of []= changes with a Rails Model, where nothing gets written
      # to Neo4j until the object is saved, during which time all the validations
      # and callbacks are run to ensure correctness
      def write_local_property(key, value)
        key_s = key.to_s
        if !@_properties.has_key?(key_s) || @_properties[key_s] != value
          attribute_will_change!(key_s)
          @_properties[key_s] = value.nil? ? attribute_defaults[key_s] : value
        end
        value
      end

      # Returns the locally stored value for the key or retrieves the value from
      # the DB if we don't have one
      def read_local_property(key)
        key = key.to_s
        if @_properties.has_key?(key)
          @_properties[key]
        else
          @_properties[key] = (persisted? && _java_entity.has_property?(key)) ? read_attribute(key) : attribute_defaults[key]
        end
      end


      module ClassMethods
        # Returns all defined properties
        def columns
          self._decl_props.keys
        end


        # Declares a property.
        # It support the following hash options:
        # <tt>:default</tt>,<tt>:null</tt>,<tt>:limit</tt>,<tt>:type</tt>,<tt>:index</tt>,<tt>:converter</tt>
        #
        # @example Set the property type,
        #   class Person < Neo4j::RailsModel
        #     property :age, :type => Time
        #   end
        #
        # @example Set the property type,
        #   class Person < Neo4j::RailsModel
        #     property :age, :default => 0
        #   end
        # @example
        #   class Person < Neo4j::RailsModel
        #     property :age, :null => false
        #   end
        # Property must be there
        #
        # @example Property has a length limit
        #   class Person < Neo4j::RailsModel
        #     property :name, :limit => 128
        #   end
        #
        # @example Index with lucene.
        #   class Person < Neo4j::RailsModel
        #     property :name, :index => :exact
        #     property :year, :index => :exact, :type => Fixnum  # index as fixnum too
        #     property :description, :index => :fulltext
        #   end
        #
        # @example Using a custom converter
        #   module MyConverter
        #     def to_java(v)
        #       "Java:#{v}"
        #     end
        #
        #     def to_ruby(v)
        #       "Ruby:#{v}"
        #     end
        #
        #     def index_as
        #       String
        #     end
        #
        #     extend self
        #   end
        #
        #   class Person < Neo4j::RailsModel
        #     property :name, :converter => MyConverter
        #   end
        #
        def property(*args)
          options = args.extract_options!
          args.each do |property_sym|
            property_setup(property_sym, options)
          end
        end


        protected
        def property_setup(property, options)
          _decl_props[property] = options
          handle_property_options_for(property, options)
          define_property_methods_for(property, options)
          define_property_before_type_cast_methods_for(property, options)
        end

        def handle_property_options_for(property, options)
          attribute_defaults[property.to_s] = options[:default] if options.has_key?(:default)

          converter = options[:converter] || Neo4j::TypeConverters.converter(_decl_props[property][:type])
          _decl_props[property][:converter] = converter

          if options.include?(:index)
            index(property, :type => options[:index], :field_type => converter.index_as)
          end

          if options.has_key?(:null) && options[:null] === false
            validates(property, :non_nil => true, :on => :create)
            validates(property, :non_nil => true, :on => :update)
          end
          validates(property, :length => {:maximum => options[:limit]}) if options[:limit]
        end

        def define_property_methods_for(property, options)
          unless method_defined?(property)
            class_eval <<-RUBY, __FILE__, __LINE__
              def #{property}
                send(:[], "#{property}")
              end
            RUBY
          end

          unless method_defined?("#{property}=".to_sym)
            class_eval <<-RUBY, __FILE__, __LINE__
              def #{property}=(value)
                send(:[]=, "#{property}", value)
              end
            RUBY
          end
        end

        def define_property_before_type_cast_methods_for(property, options)
          property_before_type_cast = "#{property}_before_type_cast"
          class_eval <<-RUBY, __FILE__, __LINE__
            def #{property_before_type_cast}=(value)
              @_properties_before_type_cast[:#{property}]=value
            end

            def #{property_before_type_cast}
              @_properties_before_type_cast.has_key?(:#{property}) ? @_properties_before_type_cast[:#{property}] : self.#{property}
            end
          RUBY
        end
      end


      protected


      # Ensure any defaults are stored in the DB
      def write_default_attributes
        self.class.attribute_defaults.each do |attribute, value|
          write_attribute(attribute, Neo4j::TypeConverters.convert(value, attribute, self.class, false)) unless changed_attributes.has_key?(attribute) || _java_node.has_property?(attribute)
        end
      end

      # Write attributes to the Neo4j DB only if they're altered
      def write_changed_attributes
        @_properties.each do |attribute, value|
          write_attribute(attribute, value) if changed_attributes.has_key?(attribute)
        end
      end



      def attribute_missing(method_id, *args, &block)
        method_name = method_id.method_name
        if property?(method_name)
          self[method_name]
        else
          super
        end
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

      def _invalid_attribute_name?(attr_name)
        attr_name.to_s[0] == ?_ && !self.class._decl_props.include?(attr_name.to_sym)
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
                          values = values_with_empty_parameters.collect do |v|
                            v.nil? ? 1 : v
                          end
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
        attributes = {}

        for pair in pairs
          multiparameter_name, value = pair
          attribute_name = multiparameter_name.split("(").first
          attributes[attribute_name] = [] unless attributes.include?(attribute_name)

          parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
          attributes[attribute_name] << [find_parameter_position(multiparameter_name), parameter_value]
        end

        attributes.each { |name, values| attributes[name] = values.sort_by { |v| v.first }.collect { |v| v.last } }
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

      def _classname
        self.class.to_s
      end

      def _classname=(value)
        write_local_property_without_type_conversion("_classname", value)
      end

    end
  end
end
