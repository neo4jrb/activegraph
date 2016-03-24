require 'active_support/inflector/inflections'
require 'neo4j/class_arguments'

module Neo4j
  module ActiveNode
    module HasN
      class Association
        include Neo4j::Shared::RelTypeConverters
        include Neo4j::ActiveNode::Dependent::AssociationMethods
        include Neo4j::ActiveNode::HasN::AssociationCypherMethods

        attr_reader :type, :name, :relationship, :direction, :dependent, :model_class

        def initialize(type, direction, name, options = {type: nil})
          validate_init_arguments(type, direction, name, options)
          @type = type.to_sym
          @name = name
          @direction = direction.to_sym
          @target_class_name_from_name = name.to_s.classify
          apply_vars_from_options(options)
        end

        def derive_model_class
          refresh_model_class! if pending_model_refresh?
          return @model_class unless @model_class.nil?
          return nil if relationship_class.nil?
          dir_class = direction == :in ? :from_class : :to_class
          return false if relationship_class.send(dir_class).to_s.to_sym == :any
          relationship_class.send(dir_class)
        end

        def refresh_model_class!
          @pending_model_refresh = @target_classes_or_nil = nil

          # Using #to_s on purpose here to take care of classes/strings/symbols
          @model_class = ClassArguments.constantize_argument(@model_class.to_s) if @model_class
        end

        def queue_model_refresh!
          @pending_model_refresh = true
        end

        def target_class_option(model_class)
          case model_class
          when nil
            @target_class_name_from_name ? "#{association_model_namespace}::#{@target_class_name_from_name}" : @target_class_name_from_name
          when Array
            model_class.map { |sub_model_class| target_class_option(sub_model_class) }
          when false
            false
          else
            model_class.to_s[0, 2] == '::' ? model_class.to_s : "::#{model_class}"
          end
        end

        def pending_model_refresh?
          !!@pending_model_refresh
        end

        def target_class_names
          option = target_class_option(derive_model_class)

          @target_class_names ||= if option.is_a?(Array)
                                    option.map(&:to_s)
                                  elsif option
                                    [option.to_s]
                                  end
        end

        def target_classes
          ClassArguments.constantize_argument(target_class_names)
        end

        def target_classes_or_nil
          @target_classes_or_nil ||= discovered_model if target_class_names
        end

        def target_where_clause
          return if model_class == false

          Array.new(target_classes).map do |target_class|
            "#{name}:`#{target_class.mapped_label_name}`"
          end.join(' OR ')
        end

        def discovered_model
          target_classes.select do |constant|
            constant.ancestors.include?(::Neo4j::ActiveNode)
          end
        end

        def target_class
          return @target_class if @target_class

          return if !(target_class_names && target_class_names.size == 1)

          class_const = ClassArguments.constantize_argument(target_class_names[0])

          @target_class = class_const
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
          when relationship_class
            relationship_class_type
          when !@relationship_type.nil?
            @relationship_type
          when @origin
            origin_type
          else
            (create || exceptional_target_class?) && decorated_rel_type(@name)
          end
        end

        attr_reader :relationship_class_name

        def relationship_class_type
          relationship_class._type.to_sym
        end

        def relationship_class
          @relationship_class ||= @relationship_class_name && @relationship_class_name.constantize
        end

        def unique?
          return relationship_class.unique? if rel_class?
          @origin ? origin_association.unique? : !!@unique
        end

        def creates_unique_option
          @unique || :none
        end

        def create_method
          unique? ? :create_unique : :create
        end

        def _create_relationship(start_object, node_or_nodes, properties)
          RelFactory.create(start_object, node_or_nodes, properties, self)
        end

        def relationship_class?
          !!relationship_class
        end
        alias_method :rel_class?, :relationship_class?

        private

        def association_model_namespace
          Neo4j::Config.association_model_namespace_string
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

        def origin_association
          target_class.associations[@origin]
        end

        def origin_type
          origin_association.relationship_type
        end

        private

        def apply_vars_from_options(options)
          @relationship_class_name = options[:rel_class] && options[:rel_class].to_s
          @relationship_type = options[:type] && options[:type].to_sym

          @model_class = options[:model_class]
          @callbacks = {before: options[:before], after: options[:after]}
          @origin = options[:origin] && options[:origin].to_sym
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

        VALID_ASSOCIATION_OPTION_KEYS = [:type, :origin, :model_class, :rel_class, :dependent, :before, :after, :unique]

        def validate_association_options!(_association_name, options)
          ClassArguments.validate_argument!(options[:model_class], 'model_class')
          ClassArguments.validate_argument!(options[:rel_class], 'rel_class')

          message = case
                    when (message = type_keys_error_message(options.keys))
                      message
                    when (unknown_keys = options.keys - VALID_ASSOCIATION_OPTION_KEYS).size > 0
                      "Unknown option(s) specified: #{unknown_keys.join(', ')}"
                    end

          fail ArgumentError, message if message
        end

        def type_keys_error_message(keys)
          type_keys = (keys & [:type, :origin, :rel_class])
          if type_keys.size > 1
            "Only one of 'type', 'origin', or 'rel_class' options are allowed for associations"
          elsif type_keys.empty?
            "The 'type' option must be specified( even if it is `nil`) or `origin`/`rel_class` must be specified"
          end
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
