module Neo4j
  module Property

    def props
      ret = {"_neo_id" => neo_id}
      iter = getPropertyKeys.iterator
      while (iter.hasNext) do
        key = iter.next
        ret[key] = get_property(key)
      end
      ret
    end

    def neo_id
      getId
    end

    def attributes
      attr = props
      attr.keys.each { |k| attr.delete k if k[0] == ?_ }
      attr
    end

    def property?(key)
      has_property?(key.to_s)
    end

    # Updates this node/relationship's properties by using the provided struct/hash.
    # If the option <code>{:strict => true}</code> is given, any properties present on
    # the node but not present in the hash will be removed from the node.
    #
    # === Parameters
    # struct_or_hash<#each_pair>:: the key and value to be set, should respond to 'each_pair'
    # options:: further options defining the context of the update, should be a Hash
    #
    # === Returns
    # self
    #
    def update(struct_or_hash, options={})
      strict = options[:strict]
      keys_to_delete = props.keys - %w(_neo_id _classname) if strict
      struct_or_hash.each_pair do |key, value|
        next if %w(_neo_id _classname).include? key.to_s
        # do not allow special properties to be mass assigned
        keys_to_delete.delete(key) if strict
        setter_meth = "#{key}=".to_sym
        if @_wrapper && @_wrapper.respond_to?(setter_meth)
          @_wrapper.send(setter_meth, value)
        else
          self[key] = value
        end
      end
      keys_to_delete.each { |key| delete_property(key) } if strict
      self
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