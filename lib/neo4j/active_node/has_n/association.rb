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

        def arrow_cypher(var = nil, properties = {}, create = false)
          relationship_name = self.relationship_name(create)
          relationship_name_cypher = ":`#{relationship_name}`" if relationship_name

          properties_string = properties.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')
          properties_string = " {#{properties_string}}" unless properties_string.empty?

          relationship_cypher = "[#{var}#{relationship_name_cypher}#{properties_string}]"
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

        def relationship_name(create = false)
          case @relationship
          when nil # Need to support false as any relationship
            if create
              "#{@target_class ? @target_class.name : 'ANY'}##{@name}"
            end
          else
            @relationship
          end
        end

        private
        
        # Should support:
        # {to: Model}
        # {from: Model}
        # {with: Model}
        # {direction: [:inbound|:outbound|:bidirectional]}
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
          options[:through]
        end
      end
    end
  end
end

