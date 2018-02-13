module Neo4j::ActiveRel
  module Query
    extend ActiveSupport::Concern

    class RecordNotFound < Neo4j::RecordNotFound; end

    module ClassMethods
      # Returns the object with the specified neo4j id.
      # @param [String,Integer] id of node to find
      # @param [Neo4j::Session] session optional
      def find(id, session = self.neo4j_session)
        fail "Unknown argument #{id.class} in find method (expected String or Integer)" if !(id.is_a?(String) || id.is_a?(Integer))
        find_by_id(id, session)
      end

      # Loads the relationship using its neo_id.
      def find_by_id(key, session = nil)
        options = session ? {session: session} : {}
        query ||= Neo4j::ActiveBase.new_query(options)
        result = query.match('()-[r]-()').where('ID(r)' => key.to_i).limit(1).return(:r).first
        fail RecordNotFound.new("Couldn't find #{name} with 'id'=#{key.inspect}", name, key) if result.blank?
        result.r
      end

      # Performs a very basic match on the relationship.
      # This is not executed lazily, it will immediately return matching objects.
      # To use a string, prefix the property with "r1"
      # @example Match with a string
      #   MyRelClass.where('r1.grade > r1')
      def where(args = {})
        where_query.where(where_string(args)).pluck(:r1)
      end

      # Performs a basic match on the relationship, returning all results.
      # This is not executed lazily, it will immediately return matching objects.
      def all
        all_query.pluck(:r1)
      end

      def first
        all_query.limit(1).order('ID(r1)').pluck(:r1).first
      end

      def last
        all_query.limit(1).order('ID(r1) DESC').pluck(:r1).first
      end

      private

      def deprecation_warning!
        ActiveSupport::Deprecation.warn 'The Neo4j::ActiveRel::Query module has been deprecated and will be removed in a future version of the gem.', caller
      end

      def where_query
        deprecation_warning!
        Neo4j::ActiveBase.new_query.match("#{cypher_string(:outbound)}-[r1:`#{self._type}`]->#{cypher_string(:inbound)}")
      end

      def all_query
        deprecation_warning!
        Neo4j::ActiveBase.new_query.match("#{cypher_string}-[r1:`#{self._type}`]->#{cypher_string(:inbound)}")
      end

      def cypher_string(dir = :outbound)
        case dir
        when :outbound
          identifier = '(n1'
          identifier + (_from_class == :any ? ')' : cypher_label(:outbound))
        when :inbound
          identifier = '(n2'
          identifier + (_to_class == :any ? ')' : cypher_label(:inbound))
        end
      end

      def cypher_label(dir = :outbound)
        target_class = dir == :outbound ? as_constant(_from_class) : as_constant(_to_class)
        ":`#{target_class.mapped_label_name}`)"
      end

      def as_constant(given_class)
        case given_class
        when String, Symbol
          given_class.to_s.constantize
        when Array
          fail "ActiveRel query methods are being deprecated and do not support Array (from|to)_class options. Current value: #{given_class}"
        else
          given_class
        end
      end

      def where_string(args)
        case args
        when Hash
          args.map { |k, v| v.is_a?(Integer) ? "r1.#{k} = #{v}" : "r1.#{k} = '#{v}'" }.join(', ')
        else
          args
        end
      end
    end
  end
end
