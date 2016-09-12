module Neo4j
  module ClassArguments
    class << self
      INVALID_CLASS_ARGUMENT_ERROR = 'option must by String, Symbol, false, nil, or an Array of Symbols/Strings'

      def valid_argument?(class_argument)
        [NilClass, String, Symbol, FalseClass].include?(class_argument.class) ||
          (class_argument.is_a?(Array) && class_argument.all? { |c| [Symbol, String].include?(c.class) })
      end

      def validate_argument!(class_argument, context)
        return if valid_argument?(class_argument)

        fail ArgumentError, "#{context} #{INVALID_CLASS_ARGUMENT_ERROR} (was #{class_argument.inspect})"
      end

      def active_node_model?(class_constant)
        class_constant.included_modules.include?(Neo4j::ActiveNode)
      end

      def constantize_argument(class_argument)
        case class_argument
        when 'any', :any, false, nil
          nil
        when Array
          class_argument.map(&method(:constantize_argument))
        else
          class_argument.to_s.constantize.tap do |class_constant|
            if !active_node_model?(class_constant)
              fail ArgumentError, "#{class_constant} is not an ActiveNode model"
            end
          end
        end
      rescue NameError
        raise ArgumentError, "Could not find class: #{class_argument}"
      end
    end
  end
end
