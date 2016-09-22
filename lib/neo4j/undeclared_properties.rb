module Neo4j
  # This mixin allows storage and update of undeclared properties in the included class
  module UndeclaredProperties
    extend ActiveSupport::Concern

    included do
      attr_accessor :undeclared_properties
    end

    def validate_attributes!(_)
    end

    def read_attribute(name)
      respond_to?(name) ? super(name) : read_undeclared_property(name.to_sym)
    end
    alias [] read_attribute

    def read_undeclared_property(name)
      _persisted_obj ? _persisted_obj.props[name] : (undeclared_properties && undeclared_properties[name])
    end

    def write_attribute(name, value)
      if respond_to? "#{name}="
        super(name, value)
      else
        add_undeclared_property(name, value)
      end
    end
    alias []= write_attribute

    def skip_update?
      super && undeclared_properties.blank?
    end

    def props_for_create
      super.merge(undeclared_properties!)
    end

    def props_for_update
      super.merge(undeclared_properties!)
    end

    def undeclared_properties!
      undeclared_properties || {}
    ensure
      self.undeclared_properties = nil
    end

    def add_undeclared_property(name, value)
      (self.undeclared_properties ||= {})[name] = value
    end
  end
end
