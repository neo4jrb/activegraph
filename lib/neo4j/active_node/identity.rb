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
  end

end