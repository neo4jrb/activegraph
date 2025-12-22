module ActiveGraph
  module Core
    class Type < Element
      def pattern(spec)
        "()-[#{spec}]-()"
      end

      def element_type
        'RELATIONSHIP'
      end
    end
  end
end
