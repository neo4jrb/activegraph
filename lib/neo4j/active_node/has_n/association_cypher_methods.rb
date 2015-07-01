module Neo4j
  module ActiveNode
    module HasN
      module AssociationCypherMethods
        # Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)
        def arrow_cypher(var = nil, properties = {}, create = false, reverse = false, length = nil)
          validate_origin!

          if create && length.present?
            fail(ArgumentError, 'rel_length option cannot be specified when creating a relationship')
          end

          direction_cypher(get_relationship_cypher(var, properties, create, length), create, reverse)
        end

        private

        def direction_cypher(relationship_cypher, create, reverse = false)
          case get_direction(create, reverse)
          when :out
            "-#{relationship_cypher}->"
          when :in
            "<-#{relationship_cypher}-"
          when :both
            "-#{relationship_cypher}-"
          end
        end

        def get_relationship_cypher(var, properties, create, length)
          relationship_type = relationship_type(create)
          relationship_name_cypher = ":`#{relationship_type}`" if relationship_type
          rel_length_cypher = cypher_for_rel_length(length)
          properties_string = get_properties_string(properties)

          "[#{var}#{relationship_name_cypher}#{rel_length_cypher}#{properties_string}]"
        end

        def get_properties_string(properties)
          p = properties.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')
          p.size == 0 ? '' : " {#{p}}"
        end

        VALID_REL_LENGTH_SYMBOLS = {
          any: '*'
        }

        def cypher_for_rel_length(length)
          return nil if length.blank?

          validate_rel_length!(length)

          case length
          when Symbol then VALID_REL_LENGTH_SYMBOLS[length]
          when Fixnum then "*#{length}"
          when Range then cypher_for_range_rel_length(length)
          when Hash then cypher_for_hash_rel_length(length)
          end
        end

        def cypher_for_range_rel_length(length)
          range_end = length.end
          range_end = nil if range_end == Float::INFINITY
          "*#{length.begin}..#{range_end}"
        end

        def cypher_for_hash_rel_length(length)
          range_end = length[:max]
          range_end = nil if range_end == Float::INFINITY
          "*#{length[:min]}..#{range_end}"
        end

        def validate_rel_length!(length)
          message = rel_length_error_message(length)
          fail(ArgumentError, "Invalid value for rel_length (#{length.inspect}): #{message}") if message
          true
        end

        def rel_length_error_message(length)
          case length
          when Fixnum then 'cannot be negative' if length < 0
          when Symbol then rel_length_symbol_error_message(length)
          when Range then rel_length_range_error_message(length)
          when Hash then rel_length_hash_error_message(length)
          else 'should be a Symbol, Fixnum, Range or Hash'
          end
        end

        def rel_length_symbol_error_message(length)
          "expecting one of #{VALID_REL_LENGTH_SYMBOLS.keys.inspect}" if !VALID_REL_LENGTH_SYMBOLS.key?(length)
        end

        def rel_length_range_error_message(length)
          if length.begin > length.end
            'cannot be a decreasing Range'
          elsif length.begin < 0
            'cannot include negative values'
          end
        end

        def rel_length_hash_error_message(length)
          'Hash keys should be a subset of [:min, :max]' if (length.keys & [:min, :max]) != length.keys
        end
      end
    end
  end
end
