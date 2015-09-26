module Neo4j::Shared
  module Initialize
    extend ActiveSupport::Concern

    # Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
    # so that we don't have to care if the node is wrapped or not.
    # @return self
    def wrapper
      self
    end

    private

    def convert_and_assign_attributes(properties)
      @attributes ||= Hash[self.class.attributes_nil_hash]
      stringify_attributes!(@attributes, properties)
      self.default_properties = properties if respond_to?(:default_properties=)
      self.class.declared_properties.convert_properties_to(self, :ruby, @attributes)
    end

    def stringify_attributes!(attr, properties)
      properties.each_pair do |k, v|
        key = self.class.declared_properties.string_key(k)
        attr[key.freeze] = v
      end
    end
  end
end
