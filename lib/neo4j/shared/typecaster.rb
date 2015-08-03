module Neo4j
  module Shared
    # This module provides a convenient way of registering a custom Typecasting class. Custom Typecasters all follow a simple pattern.
    #
    # EXAMPLE:
    #
    # .. code-block:: ruby
    #
    #   class RangeConverter
    #     class << self
    #       def primitive_type
    #         String
    #       end
    #
    #       def convert_type
    #         Range
    #       end
    #
    #       def to_db(value)
    #         value.to_s
    #       end
    #
    #       def to_ruby(value)
    #         ends = value.to_s.split('..').map { |d| Integer(d) }
    #         ends[0]..ends[1]
    #       end
    #       alias_method :call, :to_ruby
    #     end
    #
    #     include Neo4j::Shared::Typecaster
    #   end
    #
    # This would allow you to use `property :my_prop, type: Range` in a model.
    # Each method and the `alias_method` call is required. Make sure the module inclusion happens at the end of the file.
    #
    # `primitive_type` is used to fool ActiveAttr's type converters, which only recognize a few basic Ruby classes.
    #
    # `convert_type` must match the constant given to the `type` option.
    #
    # `to_db` provides logic required to transform your value into the class defined by `primitive_type`
    #
    # `to_ruby` provides logic to transform the DB-provided value back into the class expected by code using the property.
    # In other words, it should match the `convert_type`.
    #
    # Note that `alias_method` is used to make `to_ruby` respond to `call`. This is to provide compatibility with ActiveAttr.

    module Typecaster
      def self.included(other)
        Neo4j::Shared::TypeConverters.register_converter(other)
      end
    end
  end
end
