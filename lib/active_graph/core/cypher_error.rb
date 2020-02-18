module ActiveGraph
  module Core
    class CypherError < StandardError
      attr_reader :code, :original_message, :stack_trace

      def initialize(code = nil, original_message = nil, stack_trace = nil)
        @code = code
        @original_message = original_message
        @stack_trace = stack_trace

        msg = <<-ERROR
  Cypher error:
  #{ANSI::CYAN}#{code}#{ANSI::CLEAR}: #{original_message}
  #{stack_trace}
        ERROR
        super(msg)
      end

      def self.new_from(code, message, stack_trace = nil)
        error_class_from(code).new(code, message, stack_trace)
      end

      def self.error_class_from(code)
        case code
        when /(ConstraintValidationFailed|ConstraintViolation)/
          SchemaErrors::ConstraintValidationFailedError
        when /IndexAlreadyExists/
          SchemaErrors::IndexAlreadyExistsError
        when /ConstraintAlreadyExists/ # ?????
          SchemaErrors::ConstraintAlreadyExistsError
        else
          CypherError
        end
      end
    end
  end
end
