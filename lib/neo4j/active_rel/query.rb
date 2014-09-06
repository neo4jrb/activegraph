module Neo4j::ActiveRel
  module Query
    extend ActiveSupport::Concern

    module ClassMethods

      # Returns the object with the specified neo4j id.
      # @param [String,Fixnum] id of node to find
      # @param [Neo4j::Session] session optional
      def find(id, session = self.neo4j_session)
        raise "Unknown argument #{id.class} in find method (expected String or Fixnum)" if not [String, Fixnum].include?(id.class)
        find_by_id(id, session)
      end

      # Loads the relationship using its neo_id.
      def find_by_id(key, session = Neo4j::Session.current!)
        Neo4j::Relationship.load(key.to_i, session)
      end

      # Performs a very basic match on the relationship.
      # This is not executed lazily, it will immediately return matching objects.
      # To use a string, prefix the property with "r1"
      # @example Match with a string
      #   MyRelClass.where('r1.grade > r1')
      def where(args={})
        Neo4j::Session.query.match("#{cypher_string(:outbound)}-[r1:`#{self._type}`]->#{cypher_string(:inbound)}").where(where_string(args)).pluck(:r1)
      end

      # Performs a basic match on the relationship, returning all results.
      # This is not executed lazily, it will immediately return matching objects.
      def all
        all_query.pluck(:r1)
      end

      def first
        all_query.limit(1).order("ID(r1)").pluck(:r1).first
      end

      def last
        all_query.limit(1).order("ID(r1) DESC").pluck(:r1).first
      end

      private

      def all_query
        Neo4j::Session.query.match("#{cypher_string}-[r1:`#{self._type}`]->#{cypher_string(:inbound)}")
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
        target_class = dir == :outbound ? _from_class : _to_class
        ":`#{target_class.mapped_label_name}`)"
      end

      def where_string(args)
        if args.is_a?(Hash)
          args.map do |k, v|
            v.is_a?(Integer) ? "r1.#{k} = #{v}" : "r1.#{k} = '#{v}'"
          end.join(', ')
        else 
          args
        end
      end

    end
  end
end