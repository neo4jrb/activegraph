module Neo4j::Shared
  module Property
    extend ActiveSupport::Concern

    include ActiveAttr::Attributes
    include ActiveAttr::MassAssignment
    include ActiveAttr::TypecastedAttributes
    include ActiveAttr::AttributeDefaults
    include ActiveAttr::QueryAttributes
    include ActiveModel::Dirty

    class UndefinedPropertyError < RuntimeError; end
    class MultiparameterAssignmentError < StandardError; end

    attr_reader :_persisted_obj

    # TODO: Remove the commented :super entirely once this code is part of a release.
    # It calls an init method in active_attr that has a very negative impact on performance.
    def initialize(attributes = nil)
      attributes = process_attributes(attributes)
      @relationship_props = self.class.extract_association_attributes!(attributes)
      writer_method_props = extract_writer_methods!(attributes)
      validate_attributes!(attributes)
      send_props(writer_method_props)

      @_persisted_obj = nil
    end

    # Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr
    def read_attribute(name)
      super(name)
    rescue ActiveAttr::UnknownAttributeError
      nil
    end
    alias_method :[], :read_attribute

    def send_props(hash)
      return hash if hash.blank?
      hash.each { |key, value| self.send("#{key}=", value) }
    end

    protected

    # This method is defined in ActiveModel.
    # When each node is loaded, it is called once in pursuit of 'sanitize_for_mass_assignment', which this gem does not implement.
    # In the course of doing that, it calls :attributes, which is quite expensive, so we return immediately.
    def attribute_method?(attr_name) #:nodoc:
      return false if attr_name == 'sanitize_for_mass_assignment'
      super(attr_name)
    end

    private

    # Changes attributes hash to remove relationship keys
    # Raises an error if there are any keys left which haven't been defined as properties on the model
    def validate_attributes!(attributes)
      return attributes if attributes.blank?
      invalid_properties = attributes.keys.map(&:to_s) - self.attributes.keys
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

    # Gives support for Rails date_select, datetime_select, time_select helpers.
    def process_attributes(attributes = nil)
      return attributes if attributes.blank?
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
      klass = field[:type]
      klass ? klass.new(*values) : values
    end

    module ClassMethods
      extend Forwardable

      def_delegators :declared_property_manager, :serialized_properties, :serialized_properties=, :serialize, :declared_property_defaults

      def inherited(other)
        self.declared_property_manager.registered_properties.each_pair do |prop_key, prop_def|
          other.property(prop_key, prop_def.options)
        end
        super
      end

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
        prop = DeclaredProperty.new(name, options)
        prop.register
        declared_property_manager.register(prop)

        attribute(name, prop.options)
        constraint_or_index(name, options)
      end

      def undef_property(name)
        declared_property_manager.unregister(name)
        attribute_methods(name).each { |method| undef_method(method) }
        undef_constraint_or_index(name)
      end

      def declared_property_manager
        @_declared_property_manager ||= DeclaredPropertyManager.new(self)
      end

      def attribute!(name, options = {})
        super(name, options)
        define_method("#{name}=") do |value|
          typecast_value = typecast_attribute(_attribute_typecaster(name), value)
          send("#{name}_will_change!") unless typecast_value == read_attribute(name)
          super(value)
        end
      end

      # @return [Hash] A frozen hash of all model properties with nil values. It is used during node loading and prevents
      # an extra call to a slow dependency method.
      def attributes_nil_hash
        declared_property_manager.attributes_nil_hash
      end

      private

      def constraint_or_index(name, options)
        # either constraint or index, do not set both
        if options[:constraint]
          fail "unknown constraint type #{options[:constraint]}, only :unique supported" if options[:constraint] != :unique
          constraint(name, type: :unique)
        elsif options[:index]
          fail "unknown index type #{options[:index]}, only :exact supported" if options[:index] != :exact
          index(name, options) if options[:index] == :exact
        end
      end
    end
  end
end
