require "active_model/attribute_set"

module Neo4j
  class AttributeSet < ActiveModel::AttributeSet
    def [](attr_name)
      self.fetch_value(attr_name.to_s)
    end

    def []=(attr_name, attr_new_value)
      write_cast_value(attr_name.to_s, attr_new_value)
    end

    def attributes
      @attributes.to_h
    end

    def method_missing(name, *args)
      attributes.send(name, *args)
    end
  end
end
