module Neo4j::ActiveNode
  module Property
    extend ActiveSupport::Concern

    include ActiveAttr::Attributes
    include ActiveAttr::MassAssignment
    include ActiveAttr::TypecastedAttributes
    include ActiveAttr::AttributeDefaults
    include ActiveModel::Dirty

    class UndefinedPropertyError < RuntimeError
    end

    def initialize(attributes={}, options={})
      relationship_props = self.class.extract_relationship_attributes!(attributes)
      writer_method_props = extract_writer_methods!(attributes)

      validate_attributes!(attributes)

      writer_method_props.each do |key, value|
        self.send("#{key}=", value)
      end

      super(attributes, options)
      (@changed_attributes || {}).clear
    end

    def save_properties
      @previously_changed = changes
      @changed_attributes.clear
    end

    private

    # Changes attributes hash to remove relationship keys
    # Raises an error if there are any keys left which haven't been defined as properties on the model
    def validate_attributes!(attributes)
      invalid_properties = attributes.keys.map(&:to_s) - self.attributes.keys
      raise UndefinedPropertyError, "Undefined properties: #{invalid_properties.join(',')}" if invalid_properties.size > 0
    end

    def extract_writer_methods!(attributes)
      attributes.keys.inject({}) do |writer_method_props, key|
        writer_method_props[key] = attributes.delete(key) if self.respond_to?("#{key}=")

        writer_method_props
      end
    end

    module ClassMethods

      def property(name, options={})
        # Magic properties
        options[:type] = DateTime if name.to_sym == :created_at || name.to_sym == :updated_at
        attribute(name, options)
      end

      def attribute!(name, options={})
        super(name, options)
        define_method("#{name}=") do |value|
          typecast_value = typecast_attribute(typecaster_for(self.class._attribute_type(name)), value)
          send("#{name}_will_change!") unless typecast_value == read_attribute(name)
          super(value)
        end
      end

      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_relationship_attributes!(attributes)
        attributes.keys.inject({}) do |relationship_props, key|
          relationship_props[key] = attributes.delete(key) if self.has_relationship?(key)

          relationship_props
        end
      end

    end
  end

end
