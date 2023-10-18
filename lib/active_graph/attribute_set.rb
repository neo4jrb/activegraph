module ActiveGraph
  class AttributeSet < ActiveModel::AttributeSet
    def initialize(attr_hash, attr_list)
      hashmap = ActiveGraph::LazyAttributeHash.new(attr_hash, attr_list)
      super(hashmap)
    end

    def method_missing(name, *args, **kwargs, &block)
      if defined?(name)
        attributes.send(:materialize).send(name, *args, **kwargs, &block)
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
      other.is_a?(ActiveGraph::AttributeSet) ? super : to_hash == other
    end
  end
end
