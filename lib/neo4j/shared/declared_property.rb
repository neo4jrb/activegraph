module Neo4j::Shared
  # Contains methods related to the management
  class DeclaredProperty
    class IllegalPropertyError < StandardError; end

    ILLEGAL_PROPS = %w(from_node to_node start_node end_node)
    attr_reader :name, :name_string, :name_sym, :options, :magic_typecaster

    def initialize(name, options = {})
      fail IllegalPropertyError, "#{name} is an illegal property" if ILLEGAL_PROPS.include?(name.to_s)
      @name = @name_sym = name
      @name_string = name.to_s
      @options = options
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

    private

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
      options[:typecaster]  = ActiveAttr::Typecasting::ObjectTypecaster.new
      Neo4j::Shared::TypeConverters.register_converter(converter)
    end
  end
end
