module Neo4j::Shared
  class DeclaredProperty
    # None of these methods interact with the database. They only keep track of property settings in models.
    # It could (should?) handle the actual indexing/constraining, but that's TBD.
    # TODO: Fix this duplication. It's late and I'm tired.
    module Index
      def index_or_constraint?
        index?(:exact) || constraint?(:unique)
      end

      def index?(type = :exact)
        options.key?(:index) && options[:index] == type
      end

      def constraint?(type = :unique)
        options.key?(:constraint) && options[:constraint] == type
      end

      def index!(type = :exact)
        options[:index] = type
      end

      def constraint!(type = :unique)
        options[:constraint] = type
      end

      def unindex!(type = :exact)
        options.delete(:index) if index?(type)
      end

      def unconstraint!(type = :unique)
        options.delete(:constraint) if constraint?(type)
      end
    end
  end
end
