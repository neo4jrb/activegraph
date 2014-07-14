module Neo4j
  module ActiveNode
    module HasN
      class Association
        attr_reader :type, :name, :relationship, :direction

        def initialize(type, name, relationship, direction, options = {})
          raise ArgumentError if not [:has_many, :has_one].include?(type)
          raise ArgumentError if not [:inbound, :outbound].include?(direction)

          @type = type
          @name = name
          @relationship = relationship
          @direction = direction
        end

        def arrow_cypher
          relationship_cypher = (@relationship == false) ? '' : "[:`#{@relationship}`]"
          case @direction.to_sym
            when :outbound
              "-#{relationship_cypher}->"
            when :inbound
              "<-#{relationship_cypher}-"
            else
              raise ArgumentError, "Invalid relationship direction: #{@direction.inspect}"
          end
        end

      end
    end
  end
end

