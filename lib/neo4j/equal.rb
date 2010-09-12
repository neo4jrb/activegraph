module Neo4j
  module Equal
    def neo_id
      getId
    end

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