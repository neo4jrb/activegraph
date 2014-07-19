require 'active_support/inflector/inflections'

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
          @target_class_name_from_name = name.to_s.classify
          @target_class = begin
            options[:model] || @target_class_name_from_name.constantize
          rescue NameError
          end

          @relationship = options[:via] || options[:from] || options[:with]
        end

        # Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)
        def arrow_cypher(var = nil, properties = {}, create = false)
          relationship_name = self.relationship_name(create)
          relationship_name_cypher = ":`#{relationship_name}`" if relationship_name

          properties_string = properties.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')
          properties_string = " {#{properties_string}}" unless properties_string.empty?

          relationship_cypher = "[#{var}#{relationship_name_cypher}#{properties_string}]"

          direction = @direction
          direction = :outbound if create && @direction == :bidirectional

          case direction.to_sym
            when :outbound
              "-#{relationship_cypher}->"
            when :inbound
              "<-#{relationship_cypher}-"
            when :bidirectional
              "-#{relationship_cypher}-"
            else
              raise ArgumentError, "Invalid relationship direction: #{direction.inspect}"
          end
        end

        def relationship_name(create = false)
          @relationship || (create || exceptional_target_class?) && "##{@name}"
        end

        private
        
        # Determine if model class as derived from the association name would be different than the one specified via the model key
        # @example
        #   has_many :friends                 # Would return false
        #   has_many :friends, model: Friend  # Would return false
        #   has_many :friends, model: Person  # Would return true
        def exceptional_target_class?
          @target_class && @target_class.name != @target_class_name_from_name
        end

        # Determine which direction is desired for the assication from the association options
        # Can be specified by using the via/from/with keys, or by using the direction key
        #
        # @example
        #   has_many :a, via: Model
        #   has_many :a, from: Model
        #   has_many :a, with: Model
        #   has_many :a, direction: [:inbound|:outbound|:bidirectional]
        def direction_from_options(options)
          via, from, with = options.values_at(:via, :from, :with)

          raise ArgumentError, "Can only specify one of :via, :from, and :with" if [via, from, with].compact.size > 1

          if via
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

      end
    end
  end
end

