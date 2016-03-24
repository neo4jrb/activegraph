module Neo4j::Shared
  module Property
    extend ActiveSupport::Concern

    include Neo4j::Shared::MassAssignment
    include Neo4j::Shared::TypecastedAttributes
    include ActiveModel::Dirty

    class UndefinedPropertyError < Neo4j::Error; end
    class MultiparameterAssignmentError < Neo4j::Error; end

    attr_reader :_persisted_obj

    def inspect
      attribute_descriptions = inspect_attributes.map do |key, value|
        "#{Neo4j::ANSI::CYAN}#{key}: #{Neo4j::ANSI::CLEAR}#{value.inspect}"
      end.join(', ')

      separator = ' ' unless attribute_descriptions.empty?
      "#<#{Neo4j::ANSI::YELLOW}#{self.class.name}#{Neo4j::ANSI::CLEAR}#{separator}#{attribute_descriptions}>"
    end

    def initialize(attributes = nil)
      attributes = process_attributes(attributes)
      modded_attributes = inject_defaults!(attributes)
      validate_attributes!(modded_attributes)
      writer_method_props = extract_writer_methods!(modded_attributes)
      send_props(writer_method_props)
      @_persisted_obj = nil
    end

    def inject_defaults!(starting_props)
      return starting_props if self.class.declared_properties.declared_property_defaults.empty?
      self.class.declared_properties.inject_defaults!(self, starting_props || {})
    end

    def read_attribute(name)
      respond_to?(name) ? send(name) : nil
    end
    alias_method :[], :read_attribute

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
      fail UndefinedPropertyError, "Undefined properties: #{invalid_properties.join(',')}" if invalid_properties.size > 0
    end

    def extract_writer_methods!(attributes)
      return attributes if attributes.blank?
      {}.tap do |writer_method_props|
        attributes.each_key do |key|
          writer_method_props[key] = attributes.delete(key) if self.respond_to?("#{key}=")
        end
      end
    end

    DATE_KEY_REGEX = /\A([^\(]+)\((\d+)([if])\)$/
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

      # Defines a property on the class
      #
      # See active_attr gem for allowed options, e.g which type
      # Notice, in Neo4j you don't have to declare properties before using them, see the neo4j-core api.
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
        build_property(name, options) do |prop|
          attribute(prop)
        end
      end

      # @param [Symbol] name The property name
      # @param [Neo4j::Shared::AttributeDefinition] attr_def A cloned AttributeDefinition to reuse
      # @param [Hash] options An options hash to use in the new property definition
      def inherit_property(name, attr_def, options = {})
        build_property(name, options) do |prop_name|
          attributes[prop_name] = attr_def
        end
      end

      def build_property(name, options)
        DeclaredProperty.new(name, options).tap do |prop|
          prop.register
          declared_properties.register(prop)
          yield name
          constraint_or_index(name, options)
        end
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
          typecast_value = typecast_attribute(_attribute_typecaster(name), value)
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
