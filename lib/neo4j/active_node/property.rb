module Neo4j::ActiveNode
  module Property
    extend ActiveSupport::Concern

    include ActiveAttr::Attributes
    include ActiveAttr::MassAssignment
    include ActiveAttr::TypecastedAttributes
    include ActiveAttr::AttributeDefaults
    include ActiveModel::Dirty


    def initialize(attributes={}, options={})
      super(attributes, options)
      (@changed_attributes || {}).clear
    end

    def save_properties
      @previously_changed = changes
      @changed_attributes.clear
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

    end
  end

end
