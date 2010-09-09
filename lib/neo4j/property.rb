module Neo4j
  module Property

    def props
      ret = {"_neo_id" => getId()}
      iter = getPropertyKeys.iterator
      while (iter.hasNext) do
        key = iter.next
        ret[key] = getProperty(key)
      end
      ret
    end

    def attributes
      attr = props
      attr.keys.each {|k| attr.delete k if k[0] == ?_}
      attr
    end

    def property?(key)
      has_property?(key.to_s)
    end

    def [](key)
      return unless property?(key)
      get_property(key.to_s)
    end

    def []=(key, value)
      k = key.to_s
      if value.nil?
        remove_property(k)
      else
        set_property(k, value)
      end
    end
  end

end