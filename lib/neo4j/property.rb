module Neo4j
  module Property

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