# This module handles the getting, setting and updating of attributes or properties
# in a Railsy way.  This typically means not writing anything to the DB until the
# object is saved (after validation).
#
# Externally, when we talk about properties (e.g. #property?, #property_names, #properties),
# we mean all of the stored properties for this object include the 'hidden' props
# with underscores at the beginning such as _neo_id and _classname.  When we talk
# about attributes, we mean all the properties apart from those hidden ones.
module Neo4j
  module Rails
    module Attributes
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Dirty # track changes to attributes
        include ActiveModel::MassAssignmentSecurity # handle attribute hash assignment

        class_inheritable_hash :attribute_defaults
        self.attribute_defaults ||= {}

        # save the original [] and []= to use as read/write to Neo4j
        alias_method :read_attribute, :[]
        alias_method :write_attribute, :[]=

        # wrap the read/write in type conversion
        alias_method_chain :read_local_property, :type_conversion
        alias_method_chain :write_local_property, :type_conversion

        # whenever we refer to [] or []=. use our local properties store
        alias_method :[], :read_local_property
        alias_method :[]=, :write_local_property
      end

      # The behaviour of []= changes with a Rails Model, where nothing gets written
      # to Neo4j until the object is saved, during which time all the validations
      # and callbacks are run to ensure correctness
      def write_local_property(key, value)
        key_s = key.to_s
        if @properties[key_s] != value
          attribute_will_change!(key_s)
          @properties[key_s] = value
        end
        value
      end

      # Returns the locally stored value for the key or retrieves the value from
      # the DB if we don't have one
      def read_local_property(key)
        key = key.to_s
        if @properties.has_key?(key)
          @properties[key]
        else
          @properties[key] = (persisted? && _java_node.has_property?(key)) ? read_attribute(key) : attribute_defaults[key]
        end
      end

      # Mass-assign attributes.  Stops any protected attributes from being assigned.
      def attributes=(attributes, guard_protected_attributes = true)
        attributes = sanitize_for_mass_assignment(attributes) if guard_protected_attributes
        attributes.each { |k, v| respond_to?("#{k}=") ? send("#{k}=", v) : self[k] = v }
      end

      # Tracks the current changes and clears the changed attributes hash.  Called
      # after saving the object.
      def clear_changes
        @previously_changed = changes
        @changed_attributes.clear
      end

      # Return the properties from the Neo4j Node, merged with those that haven't
      # yet been saved
      def props
        ret = {}
        property_names.each do |property_name|
          ret[property_name] = respond_to?(property_name) ? send(property_name) : send(:[], property_name)
        end
        ret
      end

      # Return all the attributes for this model as a hash attr => value.  Doesn't
      # include properties that start with <tt>_</tt>.
      def attributes
        ret = {}
        attribute_names.each do |attribute_name|
          ret[attribute_name] = respond_to?(attribute_name) ? send(attribute_name) : send(:[], attribute_name)
        end
        ret
      end

      # Known properties are either in the @properties, the declared
      # attributes or the property keys for the persisted node.
      def property_names
        keys = @properties.keys + self.class._decl_props.keys.map { |k| k.to_s }
        keys += _java_node.property_keys.to_a if persisted?
        keys.flatten.uniq
      end

      # Known attributes are either in the @properties, the declared
      # attributes or the property keys for the persisted node.  Any attributes
      # that start with <tt>_</tt> are rejected
      def attribute_names
        property_names.reject { |property_name| property_name[0] == ?_ }
      end

      # Known properties are either in the @properties, the declared
      # properties or the property keys for the persisted node
      def property?(name)
        @properties.keys.include?(name) ||
            self.class._decl_props.map { |k| k.to_s }.include?(name) ||
            begin
              super
            rescue org.neo4j.graphdb.NotFoundException
              set_deleted_properties
              nil
            end
      end

      # Return true if method_name is the name of an appropriate attribute
      # method
      def attribute?(name)
        name[0] != ?_ && property?(name)
      end

      # To get ActiveModel::Dirty to work, we need to be able to call undeclared
      # properties as though they have get methods
      def method_missing(method_id, *args, &block)
        method_name = method_id.to_s
        if property?(method_name)
          self[method_name]
        else
          super
        end
      end

      def respond_to?(method_id, include_private = false)
        method_name = method_id.to_s
        if property?(method_name)
          true
        else
          super
        end
      end

      # Wrap the getter in a conversion from Java to Ruby
      def read_local_property_with_type_conversion(property)
        Neo4j::TypeConverters.to_ruby(self.class, property, read_local_property_without_type_conversion(property))
      end

      # Wrap the setter in a conversion from Ruby to Java
      def write_local_property_with_type_conversion(property, value)
        write_local_property_without_type_conversion(property, Neo4j::TypeConverters.to_java(self.class, property, value))
      end
    end
  end
end
