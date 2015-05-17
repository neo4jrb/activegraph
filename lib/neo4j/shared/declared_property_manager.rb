module Neo4j::Shared
  class DeclaredPropertyManager
    include Neo4j::Shared::TypeConverters

    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    def register(property)
      @_attributes_nil_hash = nil
      @_attributes_string_map = nil
      registered_properties[property.name] = property
      register_magic_typecaster(property) if property.magic_typecaster
      declared_property_defaults[property.name] = property.default_value if property.default_value
    end

    def declared_property_defaults
      @_default_property_values ||= {}
    end

    def registered_properties
      @_registered_properties ||= {}
    end

    def attributes_nil_hash
      @_attributes_nil_hash ||= {}.tap do |attr_hash|
        registered_properties.each_pair do |k, prop_obj|
          val = prop_obj.default_value
          attr_hash[k.to_s] = val
        end
      end.freeze
    end

    def attributes_string_map
      @_attributes_string_map ||= {}.tap do |attr_hash|
        attributes_nil_hash.each_key { |k| attr_hash[k.to_sym] = k }
      end.freeze
    end

    def unregister(name)
      # might need to be include?(name.to_s)
      fail ArgumentError, "Argument `#{name}` not an attribute" if not registered_properties[name]
      declared_prop = registered_properties[name]
      registered_properties.delete(declared_prop)
      unregister_magic_typecaster(name)
      unregister_property_default(name)
    end

    def serialize(name, coder = JSON)
      @serialize ||= {}
      @serialize[name] = coder
    end

    def serialized_properties=(serialize_hash)
      @serialized_property_keys = nil
      @serialize = serialize_hash.clone
    end

    def serialized_properties
      @serialize ||= {}
    end

    def serialized_properties_keys
      @serialized_property_keys ||= serialized_properties.keys
    end

    def magic_typecast_properties_keys
      @magic_typecast_properties_keys ||= magic_typecast_properties.keys
    end

    def magic_typecast_properties
      @magic_typecast_properties ||= {}
    end

    # The known mappings of declared properties and their primitive types.
    def upstream_primitives
      @upstream_primitives ||= {}
    end

    protected

    # Prevents repeated calls to :_attribute_type, which isn't free and never changes.
    def fetch_upstream_primitive(attr)
      upstream_primitives[attr] || upstream_primitives[attr] = klass._attribute_type(attr)
    end

    private

    def unregister_magic_typecaster(property)
      magic_typecast_properties.delete(property)
      @magic_typecast_properties_keys = nil
    end

    def unregister_property_default(property)
      declared_property_defaults.delete(property)
      @_default_property_values = nil
    end

    def register_magic_typecaster(property)
      magic_typecast_properties[property.name] = property.magic_typecaster
      @magic_typecast_properties_keys = nil
    end
  end
end
