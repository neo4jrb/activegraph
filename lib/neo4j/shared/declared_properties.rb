module Neo4j::Shared
  # The DeclaredPropertyuManager holds details about objects created as a result of calling the #property
  # class method on a class that includes Neo4j::ActiveNode or Neo4j::ActiveRel. There are many options
  # that are referenced frequently, particularly during load and save, so this provides easy access and
  # a way of separating behavior from the general Active{obj} modules.
  #
  # See Neo4j::Shared::DeclaredProperty for definitions of the property objects themselves.
  class DeclaredProperties
    include Neo4j::Shared::TypeConverters

    attr_reader :klass
    delegate :each, :each_pair, :each_key, :each_value, to: :registered_properties

    # Each class that includes Neo4j::ActiveNode or Neo4j::ActiveRel gets one instance of this class.
    # @param [#declared_properties] klass An object that has the #declared_properties method.
    def initialize(klass)
      @klass = klass
    end

    def [](key)
      registered_properties[key.to_sym]
    end

    def property?(key)
      registered_properties.key?(key.to_sym)
    end

    # @param [Neo4j::Shared::DeclaredProperty] property An instance of DeclaredProperty, created as the result of calling
    # #property on an ActiveNode or ActiveRel class. The DeclaredProperty has specifics about the property, but registration
    # makes the management object aware of it. This is necessary for type conversion, defaults, and inclusion in the nil and string hashes.
    def register(property)
      @_attributes_nil_hash = nil
      @_attributes_string_map = nil
      registered_properties[property.name] = property
      register_magic_typecaster(property) if property.magic_typecaster
      declared_property_defaults[property.name] = property.default_value if !property.default_value.nil?
    end

    def index_or_fail!(key, id_property_name, type = :exact)
      return if key == id_property_name
      fail "Cannot index undeclared property #{key}" unless property?(key)
      registered_properties[key].index!(type)
    end

    def constraint_or_fail!(key, id_property_name, type = :unique)
      return if key == id_property_name
      fail "Cannot constraint undeclared property #{property}" unless property?(key)
      registered_properties[key].constraint!(type)
    end

    # The :default option in Neo4j::ActiveNode#property class method allows for setting a default value instead of
    # nil on declared properties. This holds those values.
    def declared_property_defaults
      @_default_property_values ||= {}
    end

    def registered_properties
      @_registered_properties ||= {}
    end

    def indexed_properties
      registered_properties.select { |_, p| p.index_or_constraint? }
    end

    # During object wrap, a hash is needed that contains each declared property with a nil value.
    # The active_attr dependency is capable of providing this but it is expensive and calculated on the fly
    # each time it is called. Rather than rely on that, we build this progressively as properties are registered.
    # When the node or rel is loaded, this is used as a template.
    def attributes_nil_hash
      @_attributes_nil_hash ||= {}.tap do |attr_hash|
        registered_properties.each_pair do |k, prop_obj|
          val = prop_obj.default_value
          attr_hash[k.to_s] = val
        end
      end.freeze
    end

    # During object wrapping, a props hash is built with string keys but Neo4j-core provides symbols.
    # Rather than a `to_s` or `symbolize_keys` during every load, we build a map of symbol-to-string
    # to speed up the process. This increases memory used by the gem but reduces object allocation and GC, so it is faster
    # in practice.
    def attributes_string_map
      @_attributes_string_map ||= {}.tap do |attr_hash|
        attributes_nil_hash.each_key { |k| attr_hash[k.to_sym] = k }
      end.freeze
    end

    # @param [Symbol] k A symbol for which the String representation is sought. This might seem silly -- we could just call #to_s --
    # but when this happens many times while loading many objects, it results in a surprisingly significant slowdown.
    # The branching logic handles what happens if a property can't be found.
    # The first option attempts to find it in the existing hash.
    # The second option checks whether the key is the class's id property and, if it is, the string hash is rebuilt with it to prevent
    # future lookups.
    # The third calls `to_s`. This would happen if undeclared properties are found on the object. We could add them to the string map
    # but that would result in unchecked, un-GCed memory consumption. In the event that someone is adding properties dynamically,
    # maybe through user input, this would be bad.
    def string_key(k)
      attributes_string_map[k] || string_map_id_property(k) || k.to_s
    end

    def unregister(name)
      # might need to be include?(name.to_s)
      fail ArgumentError, "Argument `#{name}` not an attribute" if not registered_properties[name]
      registered_properties.delete(name)
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

    EXCLUDED_TYPES = [Array, Range, Regexp]
    def value_for_where(key, value)
      return value unless prop = registered_properties[key]
      return value_for_db(key, value) if prop.typecaster && prop.typecaster.convert_type == value.class

      if should_convert_for_where?(key, value)
        value_for_db(key, value)
      else
        value
      end
    end

    def value_for_db(key, value)
      return value unless registered_properties[key]
      convert_property(key, value, :to_db)
    end

    def value_for_ruby(key, value)
      return unless registered_properties[key]
      convert_property(key, value, :to_ruby)
    end

    def inject_defaults!(object, props)
      declared_property_defaults.each_pair do |k, v|
        props[k.to_sym] = v if object.send(k).nil? && props[k.to_sym].nil?
      end
      props
    end

    protected

    # Prevents repeated calls to :_attribute_type, which isn't free and never changes.
    def fetch_upstream_primitive(attr)
      registered_properties[attr].type
    end

    private

    def should_convert_for_where?(key, value)
      (value.is_a?(Array) && supports_array?(key)) || !EXCLUDED_TYPES.include?(value.class)
    end

    # @param [Symbol] key An undeclared property value found in the _persisted_obj.props hash.
    # Typically, this is a node's id property, which will not be registered as other properties are.
    # In the future, this should probably be reworked a bit. This class should either not know or care
    # about the id property or it should be in charge of it. In the meantime, this improves
    # node load performance.
    def string_map_id_property(key)
      return unless klass.id_property_name == key
      key.to_s.tap do |string_key|
        @_attributes_string_map = attributes_string_map.dup.tap { |h| h[key] = string_key }.freeze
      end
    end

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
