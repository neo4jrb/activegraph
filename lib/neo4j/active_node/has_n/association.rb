require 'active_support/inflector/inflections'

module Neo4j
  module ActiveNode
    module HasN
      class Association
        attr_reader :type, :name, :target_class, :relationship, :direction

        def initialize(type, direction, name, options = {})
          raise ArgumentError, "Invalid association type: #{type.inspect}" if not [:has_many, :has_one].include?(type)
          raise ArgumentError, "Invalid direction: #{direction.inspect}" if not [:outbound, :inbound, :bidirectional].include?(direction)

          @type = type
          @name = name
          @direction = direction
          @target_class_name_from_name = name.to_s.classify
          @target_class = begin
            if options[:model_class].nil?
              @target_class_name_from_name.constantize
            elsif options[:model_class]
              options[:model_class]
            end
          rescue NameError
            raise ArgumentError, "Could not find #{@target_class_name_from_name} class and no model_class specified"
          end

          @relationship_type = options[:type]
        end

        # Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)
        def arrow_cypher(var = nil, properties = {}, create = false)
          relationship_type = self.relationship_type(create)
          relationship_name_cypher = ":`#{relationship_type}`" if relationship_type

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

        def relationship_type(create = false)
          @relationship_type || (create || exceptional_target_class?) && "##{@name}"
        end

        private
        
        # Determine if model class as derived from the association name would be different than the one specified via the model_class key
        # @example
        #   has_many :friends                 # Would return false
        #   has_many :friends, model_class: Friend  # Would return false
        #   has_many :friends, model_class: Person  # Would return true
        def exceptional_target_class?
          @target_class && @target_class.name != @target_class_name_from_name
        end

      end
    end
  end
end

