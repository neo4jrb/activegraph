module ActiveGraph::Shared
  module Property
    extend ActiveSupport::Concern

    include ActiveGraph::Shared::MassAssignment
    include ActiveGraph::Shared::TypecastedAttributes
    include ActiveModel::Dirty

    class UndefinedPropertyError < ActiveGraph::Error; end
    class MultiparameterAssignmentError < ActiveGraph::Error; end

    attr_reader :_persisted_obj

    # This list should not be statically created. All types which have converters should by type casted
    NEO4J_DRIVER_DATA_TYPES = [Hash, Neo4j::Driver::Types::Bytes, ActiveSupport::Duration, Neo4j::Driver::Types::Point,
                               Neo4j::Driver::Types::OffsetTime, Neo4j::Driver::Types::LocalTime, Neo4j::Driver::Types::LocalDateTime]

    # TODO: Set @attribute correctly using class ActiveModel::Attribute, and after that
    # remove mutations_from_database and other ActiveModel::Dirty overrided methods
    def mutations_from_database
      @mutations_from_database ||=
        defined?(ActiveModel::ForcedMutationTracker) ? ActiveModel::ForcedMutationTracker.new(self) : ActiveModel::NullMutationTracker.instance
    end

    def inspect
      attribute_descriptions = inspect_attributes.map do |key, value|
        "#{ActiveGraph::ANSI::CYAN}#{key}: #{ActiveGraph::ANSI::CLEAR}#{value.inspect}"
      end.join(', ')

      separator = ' ' unless attribute_descriptions.empty?
      "#<#{ActiveGraph::ANSI::YELLOW}#{self.class.name}#{ActiveGraph::ANSI::CLEAR}#{separator}#{attribute_descriptions}>"
    end

    def initialize(attributes = nil)
      @attributes ||= ActiveGraph::AttributeSet.new({}, self.class.attributes.keys)
      attributes = process_attributes(attributes)
      modded_attributes = inject_defaults!(attributes)
      validate_attributes!(modded_attributes)
      writer_method_props = extract_writer_methods!(modded_attributes)
      send_props(writer_method_props)
      self.undeclared_properties = attributes
      @_persisted_obj = nil
    end

    def undeclared_properties=(_); end

    def inject_defaults!(starting_props)
      return starting_props if self.class.declared_properties.declared_property_defaults.empty?
      self.class.declared_properties.inject_defaults!(self, starting_props || {})
    end

    def read_attribute(name)
      respond_to?(name) ? send(name) : nil
    end
    alias [] read_attribute

    def send_props(hash)
      return hash if hash.blank?
      hash.each { |key, value| send("#{key}=", value) }
    end

    def reload_properties!(properties)
      @attributes = nil
      convert_and_assign_attributes(properties)
    end

    private

    # Changes attributes hash to remove relationship keys
    # Raises an error if there are any keys left which haven't been defined as properties on the model
    # TODO: use declared_properties instead of self.attributes
    def validate_attributes!(attributes)
      return attributes if attributes.blank?
      invalid_properties = attributes.keys.map(&:to_s) - self.attributes.keys
      invalid_properties.reject! { |name| self.respond_to?("#{name}=") }
      fail UndefinedPropertyError, "Undefined properties: #{invalid_properties.join(',')}" if !invalid_properties.empty?
    end

    def extract_writer_methods!(attributes)
      return attributes if attributes.blank?
      {}.tap do |writer_method_props|
        attributes.keys.each do |key|
          writer_method_props[key] = attributes.delete(key) if self.respond_to?("#{key}=")
        end
      end
    end

    DATE_KEY_REGEX = /\A([^\(]+)\((\d+)([ifs])\)$/
    # Gives support for Rails date_select, datetime_select, time_select helpers.
    def process_attributes(attributes = nil)
      return attributes if attributes.blank?
      multi_parameter_attributes = {}
      new_attributes = {}
      attributes.each_pair do |key, value|
        if key.match(DATE_KEY_REGEX)
          match = key.to_s.match(DATE_KEY_REGEX)
          found_key = match[1]
          index = match[2].to_i
          (multi_parameter_attributes[found_key] ||= {})[index] = value.empty? ? nil : value.send("to_#{$3}")
        else
          new_attributes[key] = value
        end
      end

      multi_parameter_attributes.empty? ? new_attributes : process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
    end

    def process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
      multi_parameter_attributes.each_with_object(new_attributes) do |(key, values), attributes|
        values = (values.keys.min..values.keys.max).map { |i| values[i] }
        if (field = self.class.attributes[key.to_sym]).nil?
          fail MultiparameterAssignmentError, "error on assignment #{values.inspect} to #{key}"
        end

        attributes[key] = instantiate_object(field, values)
      end
    end

    def instantiate_object(field, values_with_empty_parameters)
      return nil if values_with_empty_parameters.all?(&:nil?)
      values = values_with_empty_parameters.collect { |v| v.nil? ? 1 : v }
      klass = field.type
      klass ? klass.new(*values) : values
    end

    module ClassMethods
      extend Forwardable

      def_delegators :declared_properties, :serialized_properties, :serialized_properties=, :serialize, :declared_property_defaults

      VALID_PROPERTY_OPTIONS = %w(type default index constraint serializer typecaster).map(&:to_sym)
      # Defines a property on the class
      #
      # See active_attr gem for allowed options, e.g which type
      # Notice, in ActiveGraph you don't have to declare properties before using them, see the ActiveGraph::Coree api.
      #
      # @example Without type
      #    class Person
      #      # declare a property which can have any value
      #      property :name
      #    end
      #
      # @example With type and a default value
      #    class Person
      #      # declare a property which can have any value
      #      property :score, type: Integer, default: 0
      #    end
      #
      # @example With an index
      #    class Person
      #      # declare a property which can have any value
      #      property :name, index: :exact
      #    end
      #
      # @example With a constraint
      #    class Person
      #      # declare a property which can have any value
      #      property :name, constraint: :unique
      #    end
      def property(name, options = {})
        invalid_option_keys = options.keys.map(&:to_sym) - VALID_PROPERTY_OPTIONS
        fail ArgumentError, "Invalid options for property `#{name}` on `#{self.name}`: #{invalid_option_keys.join(', ')}" if invalid_option_keys.any?
        build_property(name, options) do |prop|
          attribute(prop)
        end
      end

      # @param [Symbol] name The property name
      # @param [ActiveGraph::Shared::AttributeDefinition] attr_def A cloned AttributeDefinition to reuse
      # @param [Hash] options An options hash to use in the new property definition
      def inherit_property(name, attr_def, options = {})
        build_property(name, options) do |prop_name|
          attributes[prop_name] = attr_def
        end
      end

      def build_property(name, options)
        decl_prop = DeclaredProperty.new(name, options).tap do |prop|
          prop.register
          declared_properties.register(prop)
          yield name
          constraint_or_index(name, options)
        end

        # If this class has already been inherited, make sure subclasses inherit property
        subclasses.each do |klass|
          klass.inherit_property name, decl_prop.clone, declared_properties[name].options
        end

        decl_prop
      end

      def undef_property(name)
        undef_constraint_or_index(name)
        declared_properties.unregister(name)
        attribute_methods(name).each { |method| undef_method(method) }
      end

      def declared_properties
        @_declared_properties ||= DeclaredProperties.new(self)
      end

      # @return [Hash] A frozen hash of all model properties with nil values. It is used during node loading and prevents
      # an extra call to a slow dependency method.
      def attributes_nil_hash
        declared_properties.attributes_nil_hash
      end

      def extract_association_attributes!(props)
        props
      end

      private

      def attribute!(name)
        remove_instance_variable('@attribute_methods_generated') if instance_variable_defined?('@attribute_methods_generated')
        define_attribute_methods([name]) unless attribute_names.include?(name)
        attributes[name.to_s] = declared_properties[name]
        define_method("#{name}=") do |value|
          typecast_value = if NEO4J_DRIVER_DATA_TYPES.include?(_attribute_type(name))
                             value
                           else
                             typecast_attribute(_attribute_typecaster(name), value)
                           end
          send("#{name}_will_change!") unless typecast_value == read_attribute(name)
          super(value)
        end
      end

      def constraint_or_index(name, options)
        # either constraint or index, do not set both
        if options[:constraint]
          fail "unknown constraint type #{options[:constraint]}, only :unique supported" if options[:constraint] != :unique
          constraint(name, type: :unique)
        elsif options[:index]
          fail "unknown index type #{options[:index]}, only :exact supported" if options[:index] != :exact
          index(name) if options[:index] == :exact
        end
      end

      def undef_constraint_or_index(name)
        prop = declared_properties[name]
        return unless prop.index_or_constraint?
        type = prop.constraint? ? :constraint : :index
        send(:"drop_#{type}", name)
      end
    end
  end
end
