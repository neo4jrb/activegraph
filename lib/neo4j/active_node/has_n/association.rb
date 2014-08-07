require 'active_support/inflector/inflections'

module Neo4j
  module ActiveNode
    module HasN
      class Association
        attr_reader :type, :name, :relationship, :direction

        def initialize(type, direction, name, options = {})
          raise ArgumentError, "Invalid association type: #{type.inspect}" if not [:has_many, :has_one].include?(type.to_sym)
          raise ArgumentError, "Invalid direction: #{direction.inspect}" if not [:out, :in, :both].include?(direction.to_sym)

          @type = type.to_sym
          @name = name
          @direction = direction.to_sym
          @target_class_name_from_name = name.to_s.classify
          @target_class_option = if options[:model_class].nil?
                            @target_class_name_from_name
                          elsif options[:model_class]
                            options[:model_class]
                          end

          setup_callbacks_from_options!(options)

          if options[:type] && options[:origin]
            raise ArgumentError, "Cannot specify both :type and :origin (#{base_declaration})"
          else
            @relationship_type = options[:type] && options[:type].to_sym
            @origin = options[:origin] && options[:origin].to_sym
          end
        end

        # Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)
        def arrow_cypher(var = nil, properties = {}, create = false)
          validate_origin!

          relationship_type = relationship_type(create)
          relationship_name_cypher = ":`#{relationship_type}`" if relationship_type

          properties_string = properties.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')
          properties_string = " {#{properties_string}}" unless properties_string.empty?

          relationship_cypher = "[#{var}#{relationship_name_cypher}#{properties_string}]"

          direction = @direction
          direction = :out if create && @direction == :both

          case direction
            when :out
              "-#{relationship_cypher}->"
            when :in
              "<-#{relationship_cypher}-"
            when :both
              "-#{relationship_cypher}-"
          end
        end

        def target_class_name
          @target_class_option.to_s if @target_class_option
        end

        def target_class
          return @target_class if @target_class

          @target_class = target_class_name.constantize if target_class_name
        rescue NameError
          raise ArgumentError, "Could not find `#{@target_class}` class and no :model_class specified"
        end

        def callback(type)

        end

        private
        
        def setup_callbacks_from_options!(options)
          # https://github.com/andreasronge/neo4j/issues/369
          # https://github.com/andreasronge/neo4j/wiki/Neo4j-v3#relationship-callbacks
          @before_create = options[:before]
          @after_create = options[:after]
        end

        def relationship_type(create = false)
          if @relationship_type
            @relationship_type
          elsif @origin
            "##{@origin}"
          else
            (create || exceptional_target_class?) && "##{@name}"
          end
        end

        # Return basic details about association as declared in the model
        # @example
        #   has_many :in, :bands
        def base_declaration
          "#{type} #{direction.inspect}, #{name.inspect}"
        end


        # Determine if model class as derived from the association name would be different than the one specified via the model_class key
        # @example
        #   has_many :friends                 # Would return false
        #   has_many :friends, model_class: Friend  # Would return false
        #   has_many :friends, model_class: Person  # Would return true
        def exceptional_target_class?
          # TODO: Exceptional if target_class.nil?? (when model_class false)

          target_class && target_class.name != @target_class_name_from_name
        end

        def validate_origin!
          if @origin
            if target_class
              if association = target_class.associations[@origin]
                if @direction == association.direction
                  raise ArgumentError, "Origin `#{@origin.inspect}` (specified in #{base_declaration}) has same direction `#{@direction}`)"
                end
              else
                raise ArgumentError, "Origin `#{@origin.inspect}` association not found for #{target_class} (specified in #{base_declaration})"
              end
            else
              raise ArgumentError, "Cannot use :origin without a model_class (implied or explicit)"
            end
          end
        end
      end
    end
  end
end

