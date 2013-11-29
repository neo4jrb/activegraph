module Neo4j::ActiveNode
  module Properties
    extend ActiveSupport::Concern

    included do
    end

    def ==(o)
      o.class == self.class && o.id == id
    end
    alias_method :eql?, :==


    # Returns an Enumerable of all (primary) key attributes
    # or nil if model.persisted? is false
    def to_key
      persisted? ? [id] : nil
    end


    NoOpTypeCaster = Proc.new{|x| x }

    def []=(k,v)
      @attributes ||= ActiveSupport::HashWithIndifferentAccess.new
      @attributes[k.to_s] = v
      to_key
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