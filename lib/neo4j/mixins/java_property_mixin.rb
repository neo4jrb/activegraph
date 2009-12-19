module Neo4j::JavaPropertyMixin

  CLASSNAME_PROPERTY = "_classname"

  def neo_id
    getId
  end

  def _wrapper=(wrapper)
    @_wrapper = wrapper
  end

  def _java_node
    self
  end
  
  def property?(key)
    has_property?(key.to_s)
  end

  def [](key)
    return unless property?(key)
    if @_wrapper and @_wrapper.class.marshal?(key)
        Marshal.load(String.from_java_bytes(get_property(key.to_s)))
    else
      get_property(key.to_s)
    end
  end

  def []=(key, value)
    k = key.to_s
    return if k == 'id'
    old_value = self[key]

    if value.nil?
      delete_property(k)
    elsif @_wrapper and @_wrapper.class.marshal?(key)
      setProperty(k, Marshal.dump(value).to_java_bytes)
    else
      value = java.lang.Double.new(value) if value.is_a? Float
      setProperty(k, value)
    end

    if (@_wrapper and k[0,1] != '_') # do not want events on internal properties
      @_wrapper.class.indexer.on_property_changed(@_wrapper, k) if @_wrapper.class.respond_to? :indexer
      Neo4j.event_handler.property_changed(@_wrapper, k, old_value, value)
    end

  end


  # Removes the property from this node.
  # For more information see JavaDoc PropertyContainer#removeProperty
  #
  # ==== Example
  #   a = Node.new
  #   a[:foo] = 2
  #   a.delete_property('foo')
  #   a[:foo] # => nil
  #
  # ==== Returns
  # true if the property was removed, false otherwise
  #
  # :api: public
  def delete_property (name)
    removed = !removeProperty(name).nil?
    if (removed and @_wrapper and name[0] != '_') # do not want events on internal properties
      @_wrapper.class.indexer.on_property_changed(self, name)
    end
    removed
  end

  # Returns a hash of all properties.
  #
  # ==== Returns
  # Hash:: property key and property value
  #
  # :api: public
  def props
    ret = {"id" => getId()}
    iter = getPropertyKeys.iterator
    while (iter.hasNext) do
      key = iter.next
      ret[key] = getProperty(key)
    end
    ret
  end

  # Updates this node/relationship's properties by using the provided struct/hash.
  # If the option <code>{:strict => true}</code> is given, any properties present on
  # the node but not present in the hash will be removed from the node.
  #
  # ==== Parameters
  # struct_or_hash<#each_pair>:: the key and value to be set
  # options<Hash>:: further options defining the context of the update
  #
  # ==== Returns
  # self
  #
  # :api: public
  def update(struct_or_hash, options={})
    strict = options[:strict]
    keys_to_delete = props.keys - %w(id classname) if strict
    struct_or_hash.each_pair do |key, value|
      next if %w(id classname).include? key.to_s # do not allow special properties to be mass assigned
      keys_to_delete.delete(key) if strict
      self[key] = value
    end
    keys_to_delete.each{|key| delete_property(key) } if strict
    self
  end


  def eql?(o)
    return false unless o.respond_to?(:neo_id)
    o.neo_id == neo_id
  end

  def ==(o)
    eql?(o)
  end


  # Loads a Neo node wrapper if possible
  # If the neo property '_classname' does not exist then it will map the neo node to the ruby class Neo4j::Node
  def wrapper
    return self unless wrapper?
    @_wrapper ||= wrapper_class.new(self)
    @_wrapper
  end

  def wrapper?
    property?(CLASSNAME_PROPERTY)
  end

  def wrapper_class
    return nil unless wrapper?
    classname = get_property(CLASSNAME_PROPERTY)
    classname.split("::").inject(Kernel) do |container, name|
      container.const_get(name.to_s)
    end
  end


end

