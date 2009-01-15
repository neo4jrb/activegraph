module Neo4j

  module Relations

    # Stores the relationship data for a Neo4j::NodeMixin class.
    #
    # :api: private
    class RelationInfo
      attr_accessor :info
      def initialize
        @info = {}
        # set defaults
        @info[:relation] = Relations::DynamicRelation
        @info[:outgoing] = true
      end
    
    
      def [](key)
        @info[key]
      end
    
      def to(clazz)
        @info[:outgoing] = true
        @info[:class] = clazz
        self
      end
    
      def from(*args) #(clazz, type)
        @info[:outgoing] = false
        if (args.size > 1)
          @info[:class] = args[0]
          @info[:type] = args[1]
        else
          @info[:type] = args[0]
        end
      
        self
      end
    
    
      def relation(rel_class)
        @info[:relation] = rel_class
        self
      end
    end
  end
end
