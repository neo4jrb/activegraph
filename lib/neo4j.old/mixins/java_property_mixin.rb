module Neo4j::JavaPropertyMixin

  # This is the property to use to map ruby classes to Neo4j Nodes
  CLASSNAME_PROPERTY = "_classname"

  # Returns the unique id of this node.
  # Ids are garbage collected over time so are only guaranteed to be unique at a specific set of time: if the node is deleted,
  # it's likely that a new node at some point will get the old id. Note: this make node ids brittle as public APIs.
  def neo_id
    getId
  end

  def _wrapper=(wrapper) # :nodoc:
    @_wrapper = wrapper
  end

  def _java_node
    self
  end

  # Returns true if this property container has a property accessible through the given key, false otherwise.
  def property?(key)
    has_property?(key.to_s)
  end

  # Returns the given property if it exist or nil if it does not exist.
  def [](key)
    return unless property?(key)
    if @_wrapper and @_wrapper.class.marshal?(key)
      Marshal.load(String.from_java_bytes(get_property(key.to_s)))
    else
      get_property(key.to_s)
    end
  end

  # Sets the given property to given value.
  # Will generate an event if the property does not start with '_' (which could be an internal property, like _classname)
  #
  def []=(key, value)
    k = key.to_s
    old_value = self[key]

    if value.nil?
      delete_property(k)
    elsif @_wrapper and @_wrapper.class.marshal?(key)
      setProperty(k, Marshal.dump(value).to_java_bytes)
    else
      value = java.lang.Double.new(value) if value.is_a? Float
      setProperty(k, value)
    end

    if (@_wrapper and k[0, 1] != '_') # do not want events on internal properties
      @_wrapper.class.indexer.on_property_changed(@_wrapper, k) if @_wrapper.class.respond_to? :indexer
      Neo4j.event_handler.property_changed(@_wrapper, k, old_value, value)
    end

  end


  # Removes the property from this node.
  # This is same as setting a property value to nil.
  #
  # For more information see JavaDoc PropertyContainer#removeProperty
  #
  # ==== Example
  #   a = Node.new
  #   a[:foo] = 2
  #   a.delete_property('foo')
  #   a[:foo] # => nil
  #
  # ==== Returns
  # <tt>true</tt> if the property was removed, <tt>false</tt> otherwise
  #
  def delete_property (name)
    removed = !removeProperty(name).nil?
    if (removed and @_wrapper and name[0] != '_') # do not want events on internal properties
      @_wrapper.class.indexer.on_property_changed(self, name)
    end
    removed
  end

  # Returns a hash of all properties.
  #
  # === Returns
  # Hash:: property key and property value with the '_neo_id' as the neo_id
  #
  def props
    ret = {"_neo_id" => getId()}
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
      next if %w(_neo_id _classname).include? key.to_s # do not allow special properties to be mass assigned
      keys_to_delete.delete(key) if strict
      setter_meth = "#{key}=".to_sym
      if @_wrapper && @_wrapper.respond_to?(setter_meth)
        @_wrapper.send(setter_meth, value)
      else
        self[key] = value
      end
    end
    keys_to_delete.each{|key| delete_property(key) } if strict
    self
  end


  def equal?(o)
    eql?(o)
  end

  def eql?(o)
    return false unless o.respond_to?(:neo_id)
    o.neo_id == neo_id
  end

  def ==(o)
    eql?(o)
  end


  # Same as neo_id but returns a String instead of a Fixnum.
  # Used by Ruby on Rails.
  #
  def to_param
    neo_id.to_s
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

  def wrapper_class  # :nodoc: 
    return nil unless wrapper?
    classname = get_property(CLASSNAME_PROPERTY)
    classname.split("::").inject(Kernel) do |container, name|
      container.const_get(name.to_s)
    end
  end


end

