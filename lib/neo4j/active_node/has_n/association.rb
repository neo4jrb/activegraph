require 'active_support/inflector/inflections'

module Neo4j
  module ActiveNode
    module HasN
      class Association
        include Neo4j::Shared::RelTypeConverters
        attr_reader :type, :name, :relationship, :direction

        def initialize(type, direction, name, options = {})
          check_valid_type_and_dir(type, direction)
          @type = type.to_sym
          @name = name
          @direction = direction.to_sym
          @target_class_name_from_name = name.to_s.classify

          set_vars_from_options(options)
        end

        def target_class_option(options)
          options[:model_class].nil? ? @target_class_name_from_name : options[:model_class]
        end

        # Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)
        def arrow_cypher(var = nil, properties = {}, create = false)
          validate_origin!
          relationship_type = relationship_type(create)
          relationship_name_cypher = ":`#{relationship_type}`" if relationship_type
          properties_string = get_properties_string(properties)
          relationship_cypher = get_relationship_cypher(var, relationship_name_cypher, properties_string)
          get_direction(relationship_cypher, create)
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
          @callbacks[type]
        end

        def perform_callback(caller, other_node, type)
          return if callback(type).nil?
          caller.send(callback(type), other_node)
        end

        def relationship_type(create = false)
          case
          when @relationship_class
            relationship_class_type
          when @relationship_type
            @relationship_type
          when @origin
            origin_type
          else
            (create || exceptional_target_class?) && decorated_rel_type(@name)
          end
        end

        def relationship_class
          @relationship_class
        end

        def relationship_class_type
          @relationship_class = @relationship_class.constantize if @relationship_class.class == String || @relationship_class == Symbol
          @relationship_class._type
        end

        def relationship_class_name
          @relationship_class_name ||= @relationship_class.respond_to?(:constantize) ? @relationship_class : @relationship_class.name
        end

        def inject_classname(properties)
          properties[Neo4j::Config.class_name_property] = relationship_class_name if @relationship_class
          properties
        end

        private

        def get_direction(relationship_cypher, create)
          dir = (create && @direction == :both) ? :out : @direction
          case dir
          when :out
            "-#{relationship_cypher}->"
          when :in
            "<-#{relationship_cypher}-"
          when :both
            "-#{relationship_cypher}-"
          end
        end

        def get_relationship_cypher(var, relationship_name_cypher, properties_string)
          "[#{var}#{relationship_name_cypher}#{properties_string}]"
        end

        def get_properties_string(properties)
          p = properties.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')
          p.size == 0 ? '' : " {#{p}}"
        end

        def origin_type
          target_class.associations[@origin].relationship_type
        end

        private

        def set_vars_from_options(options)
          validate_option_combinations(options)
          @target_class_option = target_class_option(options)
          @callbacks = {before: options[:before], after: options[:after]}
          @origin = options[:origin] && options[:origin].to_sym
          @relationship_class = options[:rel_class]
          @relationship_type  = options[:type] && options[:type].to_sym
        end

        # Return basic details about association as declared in the model
        # @example
        #   has_many :in, :bands
        def base_declaration
          "#{type} #{direction.inspect}, #{name.inspect}"
        end

        def check_valid_type_and_dir(type, direction)
          raise ArgumentError, "Invalid association type: #{type.inspect} (valid value: :has_many and :has_one)" if not [:has_many, :has_one].include?(type.to_sym)
          raise ArgumentError, "Invalid direction: #{direction.inspect} (valid value: :out, :in, and :both)" if not [:out, :in, :both].include?(direction.to_sym)
        end

        def validate_option_combinations(options)
          raise ArgumentError, "Cannot specify both :type and :origin (#{base_declaration})" if options[:type] && options[:origin]
          raise ArgumentError, "Cannot specify both :type and :rel_class (#{base_declaration})" if options[:type] && options[:rel_class]
          raise ArgumentError, "Cannot specify both :origin and :rel_class (#{base_declaration}" if options[:origin] && options[:rel_class]
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

