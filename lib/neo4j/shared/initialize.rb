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

    # We should be using #clear_changes_information
    # but right now we don't use `ActiveModel` attributes correctly and so it doesn't work
    # Once we set @attribute correctly from using class ActiveModel::Attribute
    # we will no longer need to explicitly call following method and can safely remove it
    def changed_attributes_clear!
      return if changed_attributes.nil?

      # with ActiveModel 6.0.0 we have to clear attribute changes with clear_attribute_changes
      clear_attribute_changes(self.attributes.keys)

      # changed_attributes is frozen starting with ActiveModel 5.2.0
      # Not a good long term solution
      if changed_attributes.frozen?
        @attributes_changed_by_setter = ActiveSupport::HashWithIndifferentAccess.new
      else
        changed_attributes && changed_attributes.clear
      end
    end

    # Once we set @attribute correctly from using class ActiveModel::Attribute
    # we will no longer need to explicitly call following method and can safely remove it
    def changed_attributes_selective_clear!(hash_to_clear)
      # with ActiveModel 6.0.0 we have to clear attribute changes with clear_attribute_change
      hash_to_clear.each_key { |k| clear_attribute_change(k) } if defined?(ActiveModel::ForcedMutationTracker)

      # changed_attributes is frozen starting with ActiveModel 5.2.0
      # Not a good long term solution
      if changed_attributes.frozen?
        attributes_changed_by_setter = ActiveSupport::HashWithIndifferentAccess.new(changed_attributes)
        hash_to_clear.each_key { |k| attributes_changed_by_setter.delete(k) }
        @attributes_changed_by_setter = attributes_changed_by_setter
      else
        hash_to_clear.each_key { |k| changed_attributes.delete(k) }
      end
    end
  end
end
