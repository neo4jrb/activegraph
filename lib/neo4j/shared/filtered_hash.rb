module Neo4j::Shared
  class FilteredHash
    class InvalidHashFilterType < Neo4j::Error; end
    VALID_SYMBOL_INSTRUCTIONS = [:all, :none]
    VALID_HASH_INSTRUCTIONS = [:on]
    VALID_INSTRUCTIONS_TYPES = [Hash, Symbol]

    attr_reader :base, :instructions, :instructions_type

    def initialize(base, instructions)
      @base = base
      @instructions = instructions
      @instructions_type = instructions.class
      validate_instructions!(instructions)
    end

    def filtered_base
      case instructions
      when Symbol
        filtered_base_by_symbol
      when Hash
        filtered_base_by_hash
      end
    end

    private

    def filtered_base_by_symbol
      case instructions
      when :all
        [base, {}]
      when :none
        [{}, base]
      end
    end

    def filtered_base_by_hash
      behavior_key = instructions.keys.first
      filter_keys = keys_array(behavior_key)
      [filter(filter_keys, :with), filter(filter_keys, :without)]
    end

    def key?(filter_keys, key)
      filter_keys.include?(key)
    end

    def filter(filter_keys, key)
      filtering = key == :with
      base.select { |k, _v| key?(filter_keys, k) == filtering }
    end

    def keys_array(key)
      instructions[key].is_a?(Array) ? instructions[key] : [instructions[key]]
    end

    def validate_instructions!(instructions)
      fail InvalidHashFilterType, "Filtering instructions #{instructions} are invalid" unless VALID_INSTRUCTIONS_TYPES.include?(instructions.class)
      clazz = instructions_type.name.downcase
      return if send(:"valid_#{clazz}_instructions?", instructions)
      fail InvalidHashFilterType, "Invalid instructions #{instructions}, valid options for #{clazz}: #{send(:"valid_#{clazz}_instructions")}"
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
