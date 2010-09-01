module Neo4j
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

    def self.exist?(node_id, instance = Neo4j.instance)
      self.load(node_id, instance) != nil
    end
  end
end