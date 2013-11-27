module Neo4j::ActiveNode
  module Properties
    extend ActiveSupport::Concern

    included do
      # TODO we probably want do make properties and attributes different
      alias_method :props, :attributes
    end


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



    module ClassMethods

      def property(*args)
        attribute(*args)
      end
    end

  end

end