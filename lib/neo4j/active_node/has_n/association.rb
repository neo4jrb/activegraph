require 'active_support/inflector/inflections'

module Neo4j
  module ActiveNode
    module HasN
      class Association
        include Neo4j::Shared::RelTypeConverters
        include Neo4j::ActiveNode::Dependent::AssociationMethods
        attr_reader :type, :name, :relationship, :direction, :dependent

        def initialize(type, direction, name, options = { type: nil })
          validate_init_arguments(type, direction, name, options)
          @type = type.to_sym
          @name = name
          @direction = direction.to_sym
          @target_class_name_from_name = name.to_s.classify
          apply_vars_from_options(options)
        end

        def target_class_option(model_class)
          case model_class
          when nil
            if @target_class_name_from_name
              "#{association_model_namespace}::#{@target_class_name_from_name}"
            else
              @target_class_name_from_name
            end
          when Array
            model_class.map { |sub_model_class| target_class_option(sub_model_class) }
          when false
            false
          else
            "::#{model_class}"
          end
        end

        # Return cypher partial query string for the relationship part of a MATCH (arrow / relationship definition)
        def arrow_cypher(var = nil, properties = {}, create = false, reverse = false)
          validate_origin!
          direction_cypher(get_relationship_cypher(var, properties, create), create, reverse)
        end

        def target_class_names
          @target_class_names ||= if @target_class_option.is_a?(Array)
                                    @target_class_option.map(&:to_s)
                                  elsif @target_class_option
                                    [@target_class_option.to_s]
                                  end
        end

        def target_classes_or_nil
          @target_classes_or_nil ||= discovered_model if target_class_names
        end

        def discovered_model
          target_class_names.map(&:constantize).select do |constant|
            constant.ancestors.include?(::Neo4j::ActiveNode)
          end
        end

        def target_class
          return @target_class if @target_class

          @target_class = target_class_names[0].constantize if target_class_names && target_class_names.size == 1
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

        attr_reader :relationship_class

        def relationship_class_type
          @relationship_class = @relationship_class.constantize if @relationship_class.class == String || @relationship_class == Symbol
          @relationship_class._type.to_sym
        end

        def relationship_class_name
          @relationship_class_name ||= @relationship_class.respond_to?(:constantize) ? @relationship_class : @relationship_class.name
        end

        def relationship_clazz
          @relationship_clazz ||= if @relationship_class.is_a?(String)
                                    @relationship_class.constantize
                                  elsif @relationship_class.is_a?(Symbol)
                                    @relationship_class.to_s.constantize
                                  else
                                    @relationship_class
                                  end
        end

        def inject_classname(properties)
          return properties unless @relationship_class
          properties[Neo4j::Config.class_name_property] = relationship_class_name if relationship_clazz.cached_class?(true)
          properties
        end

        def unique?
          @origin ? origin_association.unique? : !!@unique
        end

        def create_method
          unique? ? :create_unique : :create
        end

        private

        def association_model_namespace
          Neo4j::Config.association_model_namespace_string
        end

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

        def get_direction(create, reverse = false)
          dir = (create && @direction == :both) ? :out : @direction
          if reverse
            case dir
            when :in then :out
            when :out then :in
            else :both
            end
          else
            dir
          end
        end

        def get_relationship_cypher(var, properties, create)
          relationship_type = relationship_type(create)
          relationship_name_cypher = ":`#{relationship_type}`" if relationship_type
          properties_string = get_properties_string(properties)

          "[#{var}#{relationship_name_cypher}#{properties_string}]"
        end

        def get_properties_string(properties)
          p = properties.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')
          p.size == 0 ? '' : " {#{p}}"
        end

        def origin_association
          target_class.associations[@origin]
        end

        def origin_type
          origin_association.relationship_type
        end

        private

        def apply_vars_from_options(options)
          @target_class_option = target_class_option(options[:model_class])
          @callbacks = {before: options[:before], after: options[:after]}
          @origin = options[:origin] && options[:origin].to_sym
          @relationship_class = options[:rel_class]
          @relationship_type  = options[:type] && options[:type].to_sym
          @dependent = options[:dependent].try(:to_sym)
          @unique = options[:unique]
        end

        # Return basic details about association as declared in the model
        # @example
        #   has_many :in, :bands, type: :has_band
        def base_declaration
          "#{type} #{direction.inspect}, #{name.inspect}"
        end

        def validate_init_arguments(type, direction, name, options)
          validate_association_options!(name, options)
          validate_option_combinations(options)
          validate_dependent(options[:dependent].try(:to_sym))
          check_valid_type_and_dir(type, direction)
        end

        VALID_ASSOCIATION_OPTION_KEYS = [:type, :origin, :model_class, :rel_class, :dependent, :before, :after]

        def validate_association_options!(association_name, options)
          type_keys = (options.keys & [:type, :origin, :rel_class])
          message = case
                      when type_keys.size > 1
                        "Only one of 'type', 'origin', or 'rel_class' options are allowed for associations"
                      when type_keys.empty?
                        "The 'type' option must be specified( even if it is `nil`) or `origin`/`rel_class` must be specified"
                      when (unknown_keys = options.keys - VALID_ASSOCIATION_OPTION_KEYS).size > 0
                        "Unknown option(s) specified: #{unknown_keys.join(', ')}"
                      else
                        nil
                    end

          fail ArgumentError, message if message
        end

        def check_valid_type_and_dir(type, direction)
          fail ArgumentError, "Invalid association type: #{type.inspect} (valid value: :has_many and :has_one)" if ![:has_many, :has_one].include?(type.to_sym)
          fail ArgumentError, "Invalid direction: #{direction.inspect} (valid value: :out, :in, and :both)" if ![:out, :in, :both].include?(direction.to_sym)
        end

        def validate_option_combinations(options)
          [[:type, :origin],
           [:type, :rel_class],
           [:origin, :rel_class]].each do |key1, key2|
            if options[key1] && options[key2]
              fail ArgumentError, "Cannot specify both :#{key1} and :#{key2} (#{base_declaration})"
            end
          end
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
          return if not @origin

          association = origin_association

          message = case
                    when !target_class
                      'Cannot use :origin without a model_class (implied or explicit)'
                    when !association
                      "Origin `#{@origin.inspect}` association not found for #{target_class} (specified in #{base_declaration})"
                    when @direction == association.direction
                      "Origin `#{@origin.inspect}` (specified in #{base_declaration}) has same direction `#{@direction}`)"
                    end

          fail ArgumentError, message if message
        end
      end
    end
  end
end
