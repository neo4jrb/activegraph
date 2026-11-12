module ActiveGraph::Node::IdProperty
  # Provides get/set of the Id Property values.
  # Some methods
  module Accessor
    extend ActiveSupport::Concern

    attr_reader :default_property_value

    # Assigns the id property of a record that has not been saved yet.
    # The value is stored when the record is created, instead of a generated one.
    # @raise [ReadonlyIdPropertyError] if the record is persisted and the value differs from the stored one
    def default_property_value=(value)
      if _persisted_obj && value != default_property_value
        fail ReadonlyIdPropertyError, "#{self.class.name}##{default_property_key} can't be changed after save"
      end

      @default_property_value = value
    end

    def default_properties=(properties)
      @default_property_value = properties[default_property_key]
    end

    def default_property(key)
      return nil unless key == default_property_key
      default_property_value
    end

    def default_property_key
      self.class.default_property_key
    end

    def default_properties
      @default_properties ||= Hash.new(nil)
    end

    module ClassMethods
      def default_property_key
        @default_property_key ||= default_properties_keys.first
      end

      # TODO: Move this to the DeclaredProperties
      def default_property(name, &block)
        reset_default_properties(name) if default_properties.respond_to?(:size)
        default_properties[name] = block
      end

      # @return [Hash<Symbol,Proc>]
      def default_properties
        @default_property ||= {}
      end

      def default_properties_keys
        @default_properties_keys ||= default_properties.keys
      end

      def reset_default_properties(name_to_keep)
        default_properties.each_key do |property|
          @default_properties_keys = nil
          next if property == name_to_keep

          undef_method(property)
          undef_method("#{property}=") if method_defined?("#{property}=")
        end
        @default_properties_keys = nil
        @default_property_key = nil
        @default_property = {}
      end

      def default_property_values(instance)
        default_properties.each_with_object({}) do |(key, block), result|
          result[key] = instance.default_property(key) || block.call(instance)
        end
      end
    end
  end
end
