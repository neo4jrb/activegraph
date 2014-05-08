module Neo4j::ActiveNode
  module Identity

    def ==(o)
      o.class == self.class && o.id == id
    end
    alias_method :eql?, :==

    # Returns an Enumerable of all (primary) key attributes
    # or nil if model.persisted? is false
    def to_key
      persisted? ? [id] : nil
    end

    # @return [Fixnum, nil] the neo4j id of the node if persisted or nil
    def neo_id
      _persisted_node ? _persisted_node.neo_id : nil
    end

    # @return [String, nil] same as #neo_id
    def id
      neo_id.is_a?(Integer) ? neo_id : nil
    end


  end

end
