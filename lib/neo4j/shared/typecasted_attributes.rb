module Neo4j::Shared
  # TypecastedAttributes allows types to be declared for your attributes
  #
  # Types are declared by passing the :type option to the attribute class
  # method. After a type is declared, attribute readers will convert any
  # assigned attribute value to the declared type. If the assigned value
  # cannot be cast, nil will be returned instead. You can access the original
  # assigned value using the before_type_cast methods.
  #
  # See {Typecasting} for the currently supported types.
  #
  # @example Usage
  #   class Person
  #     include Neo4j::Shared::TypecastedAttributes
  #     attribute :age, :type => Integer
  #   end
  #
  #   person = Person.new
  #   person.age = "29"
  #   person.age #=> 29
  #   person.age_before_type_cast #=> "29"
  #
  # Originally part of ActiveAttr, https://github.com/cgriego/active_attr
  module TypecastedAttributes
    extend ActiveSupport::Concern
    include Neo4j::Shared::Attributes

    included do
      attribute_method_suffix '_before_type_cast'
    end

    # Read the raw attribute value
    #
    # @example Reading a raw age value
    #   person.age = "29"
    #   person.attribute_before_type_cast(:age) #=> "29"
    #
    # @param [String, Symbol, #to_s] name Attribute name
    #
    # @return [Object, nil] The attribute value before typecasting
    def attribute_before_type_cast(name)
      @attributes ||= {}
      @attributes[name.to_s]
    end

    private

    # Reads the attribute and typecasts the result
    def attribute(name)
      typecast_attribute(_attribute_typecaster(name), super)
    end

    def typecast_attribute(typecaster, value)
      self.class.typecast_attribute(typecaster, value)
    end

    # Calculates an attribute type
    #
    # @private
    def _attribute_type(attribute_name)
      self.class._attribute_type(attribute_name)
    end

    # Resolve an attribute typecaster
    #
    # @private
    def _attribute_typecaster(attribute_name)
      type = _attribute_type(attribute_name)
      caster = self.class.attributes[attribute_name].typecaster || Neo4j::Shared::TypeConverters.typecaster_for(type)
      caster || fail(Neo4j::UnknownTypeConverterError, "Unable to cast to type #{type}")
    end

    module ClassMethods
      # Returns the class name plus its attribute names and types
      #
      # @example Inspect the model's definition.
      #   Person.inspect
      #
      # @return [String] Human-readable presentation of the attributes
      def inspect
        inspected_attributes = attribute_names.sort.map { |name| "#{name}: #{_attribute_type(name)}" }
        attributes_list = "(#{inspected_attributes.join(', ')})" unless inspected_attributes.empty?
        "#{name}#{attributes_list}"
      end

      # Calculates an attribute type
      #
      # @private
      def _attribute_type(attribute_name)
        attributes[attribute_name].type || Object
      end

      def typecast_attribute(typecaster, value)
        Neo4j::Shared::TypeConverters.typecast_attribute(typecaster, value)
      end
    end
  end
end
