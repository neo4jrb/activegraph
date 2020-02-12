require "active_model/attribute_set"

module Neo4j
  class AttributeSet < ActiveModel::AttributeSet
    def initialize(attr_hash, attr_list)
      hashmap = Neo4j::LazyAttributeHash.new(attr_hash, attr_list)
      super(hashmap)
    end

    def method_missing(name, *args)
      attributes.send(:materialize).send(name, *args)
    end

    def keys
      attributes.send(:materialize).keys
    end
  end
end
