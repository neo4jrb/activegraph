module Neo4j::Shared::Property
  class FilteredProperties
    class InvalidPropertyFilterType < Neo4j::Neo4jrbError; end
    VALID_SYMBOL_INSTRUCTIONS = [:all, :none]
    VALID_HASH_INSTRUCTIONS = [:on, :except]

    attr_reader :properties, :instructions, :instructions_type

    def initialize(properties, instructions)
      @properties = properties
      @instructions = instructions
      @instructions_type = instructions.class
      validate_instructions!(instructions)
    end

    def filtered_properties
      case instructions
      when Symbol
        filtered_properties_by_symbol
      when Hash
        filtered_properties_by_hash
      end
    end

    private

    def filtered_properties_by_symbol
      case instructions
      when :all
        [properties, {}]
      when :none
        [{}, properties]
      end
    end

    def filtered_properties_by_hash
      behavior_key = instructions.keys.first
      filter_keys = keys_array(behavior_key)
      base = [filter(filter_keys, :with), filter(filter_keys, :without)]
      behavior_key == :on ? base : base.reverse
    end

    def key?(filter_keys, key)
      filter_keys.include?(key)
    end

    def filter(filter_keys, key)
      filtering = key == :with
      properties.select { |k, _v| key?(filter_keys, k) == filtering }
    end

    def keys_array(key)
      instructions[key].is_a?(Array) ? instructions[key] : [instructions[key]]
    end

    def validate_instructions!(instructions)
      clazz = instructions_type.name.downcase
      return if send(:"valid_#{clazz}_instructions?", instructions)
      fail InvalidPropertyFilterType, "Invalid instructions #{instructions}, valid options for #{clazz}: #{send(:"valid_#{clazz}_instructions")}"
    end

    def valid_symbol_instructions?(instructions)
      valid_symbol_instructions.include?(instructions)
    end

    def valid_hash_instructions?(instructions)
      valid_hash_instructions.include?(instructions.keys.first)
    end

    def valid_symbol_instructions
      VALID_SYMBOL_INSTRUCTIONS
    end

    def valid_hash_instructions
      VALID_HASH_INSTRUCTIONS
    end
  end
end
