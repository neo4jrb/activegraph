module Neo4j

  # == This mixin is used for both nodes and relationships to decide if two entities are equal or not.
  #
  module Equal
    def equal?(o)
      eql?(o)
    end

    def eql?(o)
      return false unless o.respond_to?(:getId)
      o.getId == getId
    end

    def ==(o)
      eql?(o)
    end

  end

end