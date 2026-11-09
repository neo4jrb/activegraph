module ActiveGraph
  module Node
    module HasN
      # The relationship part of a pattern for an association, as a cypher-dsl relationship
      # pattern (`relationship_pattern`) or as Cypher text (`arrow_cypher`).
      module AssociationCypherMethods
        PATTERN_METHODS = {out: :relationship_to, in: :relationship_from, both: :relationship_between}.freeze

        # The pattern `left-[var:TYPE*length {properties}]-right` in the direction of the association.
        # `left` is a node or a pattern to extend, `right` a node.
        # @return [CypherDSL::Relationship, CypherDSL::RelationshipChain]
        def relationship_pattern(left, right, var: nil, properties: {}, create: false, reverse: false, length: nil)
          validate_origin!

          if create && length.present?
            fail(ArgumentError, 'rel_length option cannot be specified when creating a relationship')
          end

          types = Array(relationship_type(create).presence) # nil or false for an untyped match
          pattern = left.public_send(PATTERN_METHODS[get_direction(create, reverse)], right, *types)
          pattern = pattern.named(var) if var
          pattern = pattern.with_properties(properties) if properties.present?
          with_rel_length(pattern, length)
        end

        # Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)
        def arrow_cypher(var = nil, properties = {}, create = false, reverse = false, length = nil)
          options = {var: var, properties: properties, create: create, reverse: reverse, length: length}
          pattern = relationship_pattern(CypherDSL::Cypher.any_node, CypherDSL::Cypher.any_node, **options)
          ActiveGraph::Base.renderer.render_fragment(pattern).delete_prefix('()').delete_suffix('()')
        end

        private

        VALID_REL_LENGTH_SYMBOLS = {
          any: '*'
        }.freeze

        def with_rel_length(pattern, length)
          return pattern if length.blank?

          validate_rel_length!(length)

          case length
          when Symbol then pattern.unbounded
          when Integer then pattern.length(length, length)
          when Range then pattern.length(length.begin, finite_end(length.end))
          when Hash then pattern.length(length[:min], finite_end(length[:max]))
          end
        end

        def finite_end(value)
          value == Float::INFINITY ? nil : value
        end

        def validate_rel_length!(length)
          message = rel_length_error_message(length)
          fail(ArgumentError, "Invalid value for rel_length (#{length.inspect}): #{message}") if message

          true
        end

        def rel_length_error_message(length)
          case length
          when Integer then 'cannot be negative' if length < 0
          when Symbol then rel_length_symbol_error_message(length)
          when Range then rel_length_range_error_message(length)
          when Hash then rel_length_hash_error_message(length)
          else 'should be a Symbol, Integer, Range or Hash'
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
