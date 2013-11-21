module Neo4j::ActiveNode
  module Properties
    NoOpTypeCaster = Proc.new{|x| x }

    def []=(k,v)
      @attributes[k.to_s] = v
    end

    def [](k)
      @attributes[k.to_s]
    end

  end
end