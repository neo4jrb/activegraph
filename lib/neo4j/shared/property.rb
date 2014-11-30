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
    class IllegalPropertyError < StandardError; end

    ILLEGAL_PROPS = %w[from_node to_node start_node end_node]

    attr_reader :_persisted_obj

    def initialize(attributes={}, options={})
      attributes = process_attributes(attributes)
      @relationship_props = self.class.extract_association_attributes!(attributes)
      writer_method_props = extract_writer_methods!(attributes)
      validate_attributes!(attributes)
      send_props(writer_method_props) unless writer_method_props.nil?

      @_persisted_obj = nil

      super(attributes, options)
    end

    # Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr
    def read_attribute(name)
      super(name)
    rescue ActiveAttr::UnknownAttributeError
      nil
    end
    alias_method :[], :read_attribute

    def default_properties=(properties)
      keys = self.class.default_properties.keys
      @default_properties = properties.select {|key| keys.include?(key) }
    end

    def default_property(key)
      default_properties[key.to_sym]
    end

    def default_properties
      @default_properties ||= Hash.new(nil)
      # keys = self.class.default_properties.keys
      # _persisted_obj.props.reject{|key| !keys.include?(key)}
    end

    def send_props(hash)
      hash.each do |key, value|
        self.send("#{key}=", value)
      end
    end

    private

    # Changes attributes hash to remove relationship keys
    # Raises an error if there are any keys left which haven't been defined as properties on the model
    def validate_attributes!(attributes)
      invalid_properties = attributes.keys.map(&:to_s) - self.attributes.keys
      raise UndefinedPropertyError, "Undefined properties: #{invalid_properties.join(',')}" if invalid_properties.size > 0
    end

    def extract_writer_methods!(attributes)
      attributes.keys.inject({}) do |writer_method_props, key|
        writer_method_props[key] = attributes.delete(key) if self.respond_to?("#{key}=")

        writer_method_props
      end
    end

    # Gives support for Rails date_select, datetime_select, time_select helpers.
    def process_attributes(attributes = nil)
      multi_parameter_attributes = {}
      new_attributes = {}
      attributes.each_pair do |key, value|
        if key =~ /\A([^\(]+)\((\d+)([if])\)$/
          found_key, index = $1, $2.to_i
          (multi_parameter_attributes[found_key] ||= {})[index] = value.empty? ? nil : value.send("to_#{$3}")
        else
          new_attributes[key] = value
        end
      end

      multi_parameter_attributes.empty? ? new_attributes : process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
    end

    def process_multiparameter_attributes(multi_parameter_attributes, new_attributes)
      multi_parameter_attributes.each_pair do |key, values|
        begin
          values = (values.keys.min..values.keys.max).map { |i| values[i] }
          field = self.class.attributes[key.to_sym]
          new_attributes[key] = instantiate_object(field, values)
        rescue => e
          raise MultiparameterAssignmentError, "error on assignment #{values.inspect} to #{key}"
        end
      end
      new_attributes
    end

    def instantiate_object(field, values_with_empty_parameters)
      return nil if values_with_empty_parameters.all? { |v| v.nil? }
      values = values_with_empty_parameters.collect { |v| v.nil? ? 1 : v }
      klass = field[:type]
      klass ? klass.new(*values) : values
    end

    module ClassMethods

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
      def property(name, options={})
        check_illegal_prop(name)
        magic_properties(name, options)
        attribute(name, options)
        constraint_or_index(name, options)
      end

      def undef_property(name)
        raise ArgumentError, "Argument `#{name}` not an attribute" if not attribute_names.include?(name.to_s)

        attribute_methods(name).each do |method|
          undef_method(method)
        end

        undef_constraint_or_index(name)
      end

      def default_property(name, &block)
        reset_default_properties(name) if default_properties.respond_to?(:size)
        default_properties[name] = block
      end

      # @return [Hash<Symbol,Proc>]
      def default_properties
        @default_property ||= {}
      end

      def reset_default_properties(name_to_keep)
        default_properties.each_key do |property|
          undef_method(property) unless property == name_to_keep
        end
        @default_property = {}
      end

      def default_property_values(instance)
        default_properties.each_with_object({}) do |(key, block),result|
          result[key] = block.call(instance)
        end
      end

      def attribute!(name, options={})
        super(name, options)
        define_method("#{name}=") do |value|
          typecast_value = typecast_attribute(_attribute_typecaster(name), value)
          send("#{name}_will_change!") unless typecast_value == read_attribute(name)
          super(value)
        end
      end

      private

      def constraint_or_index(name, options)
        # either constraint or index, do not set both
        if options[:constraint]
          raise "unknown constraint type #{options[:constraint]}, only :unique supported" if options[:constraint] != :unique
          constraint(name, type: :unique)
        elsif options[:index]
          raise "unknown index type #{options[:index]}, only :exact supported" if options[:index] != :exact
          index(name, options) if options[:index] == :exact
        end
      end

      def check_illegal_prop(name)
        if ILLEGAL_PROPS.include?(name.to_s)
          raise IllegalPropertyError, "#{name} is an illegal property"
        end
      end

      # Tweaks properties
      def magic_properties(name, options)
        set_stamp_type(name, options)
        set_time_as_datetime(options)
      end

      def set_stamp_type(name, options)
        options[:type] ||= DateTime if (name.to_sym == :created_at || name.to_sym == :updated_at)
      end

      # ActiveAttr does not handle "Time", Rails and Neo4j.rb 2.3 did
      # Convert it to DateTime in the interest of consistency
      def set_time_as_datetime(options)
        options[:type] = DateTime if options[:type] == Time
      end

    end

  end

end
