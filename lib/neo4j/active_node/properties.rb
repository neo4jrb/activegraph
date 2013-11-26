module Neo4j::ActiveNode
  module Properties
    NoOpTypeCaster = Proc.new{|x| x }

    def []=(k,v)
      @attributes ||= ActiveSupport::HashWithIndifferentAccess.new
      @attributes[k.to_s] = v
    end

    def [](k)
      if self.class.attributes[k.to_s]
        send(:attribute, k.to_s)
      else
        @attributes[k.to_s] if @attributes
      end
    end
  end
end