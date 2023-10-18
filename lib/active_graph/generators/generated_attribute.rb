module ActiveGraph
  module Generators
    module GeneratedAttribute #:nodoc:
      def type_class
        case type.to_s.downcase
        when 'any' then 'any'
        when 'datetime' then 'DateTime'
        when 'date' then 'Date'
        when 'integer', 'number', 'fixnum' then 'Integer'
        when 'float' then 'Float'
        else
          'String'
        end
      end
    end
  end
end
