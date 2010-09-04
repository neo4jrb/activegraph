module Neo4j



  module Property

# Returns true if this property container has a property accessible through the given key, false otherwise.
    def property?(key)
      has_property?(key.to_s)
    end

    # Returns the given property if it exist or nil if it does not exist.
    def [](key)
      return unless property?(key)
      get_property(key.to_s)
    end

    # Sets the given property to given value.
    # Will generate an event if the property does not start with '_' (which could be an internal property, like _classname)
    #
    def []=(key, value)
      k = key.to_s
      if value.nil?
        delete_property(k)
      else
#        value = java.lang.Double.new(value) if value.is_a? Float
        setProperty(k, value)
      end
    end
  end

  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    include Neo4j::Property
  end


  class Node
    def self.new(*args)
      # creates a new node using the default db instance when given no args

      # the first argument can be an hash of properties to set
      props = args[0].respond_to?(:each_pair) && args[0]

      # a db instance can be given, is the first argument if that was not a hash, or otherwise the second
      instance = (!props && args[0]) || args[1]
      create(props, instance)
    end

    def self.create(props, instance)
      db = instance || Neo4j.instance
      node = db.create_node
      props.each_pair { |k, v| node.set_property(k.to_s, v) } if props
      node
    end


    def self.load(node_id, instance = Neo4j.instance)
      instance.get_node_by_id(node_id.to_i)
    rescue org.neo4j.graphdb.NotFoundException
      nil
    end

    def self.exist?(node_or_node_id, instance = Neo4j.instance)
      id = node_or_node_id.respond_to?(:id) ? node_or_node_id.id : node_or_node_id
      self.load(id, instance) != nil
    end
  end
end