require 'active_model/attribute_set'

module Neo4j
  class AttributeSet < ActiveModel::AttributeSet
    def initialize(attr_hash, attr_list)
      hashmap = Neo4j::LazyAttributeHash.new(attr_hash, attr_list)
      super(hashmap)
    end

    def method_missing(name, *args)
      if defined?(name)
        attributes.send(:materialize).send(name, *args)
      else
        super
      end
    end

    def respond_to_missing?(method, *)
      attributes.send(:materialize).respond_to?(method) || super
    end

    def keys
      attributes.send(:materialize).keys
    end

    def ==(other)
      return self.to_hash == other unless other.is_a?(Neo4j::AttributeSet)
      super
    end
  end
end
