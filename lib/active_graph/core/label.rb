module ActiveGraph
  module Core
    class Label < Element
      def pattern(spec)
        "(#{spec})"
      end

      def element_type
        'NODE'
      end
    end
  end
end
