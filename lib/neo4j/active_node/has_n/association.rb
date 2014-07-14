module Neo4j
  module ActiveNode
    module HasN
      class Association
        attr_reader :type, :name, :target_class, :relationship, :direction

        def initialize(type, name, options = {})
          raise ArgumentError, "Invalid association type: #{type.inspect}" if not [:has_many, :has_one].include?(type)

          @type = type
          @name = name
          @direction = direction_from_options(options)
          @target_class = target_class_from_options(options)
          @relationship = relationship_from_options(options)
        end

        def arrow_cypher
          relationship_cypher = (@relationship == false) ? '' : "[:`#{@relationship}`]"
          case @direction.to_sym
            when :outbound
              "-#{relationship_cypher}->"
            when :inbound
              "<-#{relationship_cypher}-"
            when :bidirectional
              "-#{relationship_cypher}-"
            else
              raise ArgumentError, "Invalid relationship direction: #{@direction.inspect}"
          end
        end

        private
        
        # {to: Person}
        # {from: Person}
        # {with: Person}
        # {direction: :inbound}
        def direction_from_options(options)
          to, from, with, direction = options.values_at(:to, :from, :with, :direction)

          raise ArgumentError, "Can only specify one of :to, :from, and :with" if [to, from, with].compact.size > 1

          if to
            :outbound
          elsif from
            :inbound
          elsif with
            :bidirectional
          elsif direction
            raise ArgumentError, "Invalid direction: #{direction.inspect}" if not [:outbound, :inbound, :bidirectional].include?(direction)
            direction
          else
            :bidirectional
          end
        end

        def target_class_from_options(options)
          options[:to] || options[:from] || options[:with]
        end

        def relationship_from_options(options)
          relationship = options[:through]
          # Need to support false as matching any relationship
          relationship = "#{@target_class ? @target_class.name : 'ANY'}##{@name}" if relationship.nil?
          relationship
        end
      end
    end
  end
end

