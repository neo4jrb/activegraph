module Neo4j::Shared
  # Contains methods related to the management
  class DeclaredProperty
    include Comparable

    class IllegalPropertyError < Neo4j::Error; end
    include Neo4j::Shared::DeclaredProperty::Index

    ILLEGAL_PROPS = %w(from_node to_node start_node end_node)
    attr_reader :name, :name_string, :name_sym, :options, :magic_typecaster

    def initialize(name, options = {})
      fail IllegalPropertyError, "#{name} is an illegal property" if ILLEGAL_PROPS.include?(name.to_s)
      fail TypeError, "can't convert #{name.class} into Symbol" unless name.respond_to?(:to_sym)
      @name = @name_sym = name.to_sym
      @name_string = name.to_s
      @options = options
      fail_invalid_options!
    end

    # Compare attribute definitions
    #
    # @example
    #   attribute_definition <=> other
    #
    # @param [Neo4j::Shared::DeclaredProperty, Object] other The other
    #   attribute definition to compare with.
    #
    # @return [-1, 0, 1, nil]
    def <=>(other)
      return nil unless other.instance_of? self.class
      return nil if name == other.name && options != other.options
      self.to_s <=> other.to_s
    end

    def inspect
      options_description = options.map { |key, value| "#{key.inspect} => #{value.inspect}" }.sort.join(', ')
      inspected_options = ", #{options_description}" unless options_description.empty?
      "attribute :#{name}#{inspected_options}"
    end

    def to_s
      name.to_s
    end

    def to_sym
      name
    end

    def [](key)
      respond_to?(key) ? public_send(key) : nil
    end

    def register
      register_magic_properties
    end

    def type
      options[:type]
    end

    def typecaster
      options[:typecaster]
    end

    def default_value
      options[:default]
    end
    alias_method :default, :default_value

    def fail_invalid_options!
      case
      when index?(:exact) && constraint?(:unique)
        fail Neo4j::InvalidPropertyOptionsError,
             "#Uniqueness constraints also provide exact indexes, cannot set both options on property #{name}"
      end
    end

    private

    def option_with_value!(key, value)
      options[key] = value
      fail_invalid_options!
    end

    def option_with_value?(key, value)
      options[key] == value
    end

    # Tweaks properties
    def register_magic_properties
      options[:type] ||= Neo4j::Config.timestamp_type if timestamp_prop?

      register_magic_typecaster
      register_type_converter
    end

    def timestamp_prop?
      name.to_sym == :created_at || name.to_sym == :updated_at
    end

    def register_magic_typecaster
      found_typecaster = Neo4j::Shared::TypeConverters.typecaster_for(options[:type])
      return unless found_typecaster && found_typecaster.respond_to?(:primitive_type)
      options[:typecaster] = found_typecaster
      @magic_typecaster = options[:type]
      options[:type] = found_typecaster.primitive_type
    end

    def register_type_converter
      converter = options[:serializer]
      return unless converter
      options[:type]        = converter.convert_type
      options[:typecaster]  = Neo4j::Shared::TypeConverters::ObjectConverter
      Neo4j::Shared::TypeConverters.register_converter(converter)
    end
  end
end
