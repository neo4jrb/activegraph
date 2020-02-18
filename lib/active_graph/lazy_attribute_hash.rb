require 'active_model/attribute_set'

module ActiveGraph
  class LazyAttributeHash < ActiveModel::LazyAttributeHash
    def initialize(values, attr_list)
      @types = {}
      @values = {}
      @additional_types = {}
      @materialized = false
      @delegate_hash = values

      @default_attributes = process_default_attributes(attr_list)
    end

    private

    def marshal_load(values)
      initialize(values[4], values[3])
    end

    def process_default_attributes(attr_list)
      if attr_list.is_a?(Hash)
        attr_list
      else
        # initialize default attributes map with nil values
        attr_list.each_with_object({}) do |name, map|
          map[name] = nil
        end
      end
    end

    # we are using with_cast_value here because at the moment casting is being managed by
    # Neo4j and not in ActiveModel
    def assign_default_value(name)
      delegate_hash[name] = ActiveModel::Attribute.with_cast_value(name, default_attributes[name].dup, nil)
    end
  end
end
