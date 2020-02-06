require "active_model/attribute_set"

module Neo4j
  class AttributeSet < ActiveModel::AttributeSet
    def initialize(attr_hash)
      hashmap = Neo4j::LazyAttributeHash.new(attr_hash)
      super(hashmap)
    end

    def method_missing(name, *args)
      attributes.send(name, *args)
    end

    def key?(name)
      attributes.key?(name)
    end

    def keys
      attributes.send(:delegate_hash).keys
    end
  end
end
