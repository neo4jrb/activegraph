module Neo4j

  class Value
    include Neo4j::Property
    include org.neo4j.graphdb.Node

    def initialize(*args)
      # the first argument can be an hash of properties to set
      @props = {}
      if args[0].respond_to?(:each_pair)
        args[0].each_pair { |k, v| set_property(k.to_s, v) }
      end
    end

    # override Neo4j::Property#props
    def props
      @props
    end

    def getId
      nil
    end

    # Pretend this object is a Java Node
    def has_property?(key)
      !@props[key].nil?
    end

    def set_property(key,value)
      @props[key] = value
    end

    def get_property(key)
      @props[key]
    end

    def remove_property(key)
      @props.delete(key)
    end

  end

end