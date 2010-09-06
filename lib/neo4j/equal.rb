module Neo4j
  module Equal
    def equal?(o)
      eql?(o)
    end

    def eql?(o)
      return false unless o.respond_to?(:id)
      o.id == id
    end


    def ==(o)
      eql?(o)
    end
  end

end