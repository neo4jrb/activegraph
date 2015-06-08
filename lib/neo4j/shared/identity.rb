module Neo4j::Shared
  module Identity
    def ==(other)
      other.class == self.class && other.id == id
    end
    alias_method :eql?, :==

    # Returns an Enumerable of all (primary) key attributes
    # or nil if model.persisted? is false
    def to_key
      _persisted_obj ? [id] : nil
    end

    # @return [Integer, nil] the neo4j id of the node if persisted or nil
    def neo_id
      _persisted_obj ? _persisted_obj.neo_id : nil
    end

    def id
      id = neo_id
      id.is_a?(Integer) ? id : nil
    end

    def hash
      id.hash
    end
  end
end
