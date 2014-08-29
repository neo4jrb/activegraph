module Neo4j
  module ActiveNode
    module QueryMethods
      class InvalidParameterError < StandardError; end

      def exists?(node_id=nil)
        raise(InvalidParameterError, ':exists? only accepts neo_ids') unless node_id.is_a?(Integer) || node_id.nil?
        start_q = self.query_as(:n)
        end_q = node_id.nil? ? start_q : start_q.where("ID(n) = #{node_id}")
        end_q.return("COUNT(n) AS count").first.count > 0
      end

      def exists?(node_id=nil)
        raise(InvalidParameterError, ':exists? only accepts neo_ids') unless node_id.is_a?(Integer) || node_id.nil?
        start_q = self.query_as(:n)
        end_q = node_id.nil? ? start_q : start_q.where("ID(n) = #{node_id}")
        end_q.return("COUNT(n) AS count").first.count > 0
      end

      # Returns the first node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def first
        self.query_as(:n).limit(1).order('ID(n)').pluck(:n).first
      end

      # Returns the last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def last
        self.query_as(:n).limit(1).order('ID(n) DESC').pluck(:n).first
      end

      # @return [Fixnum] number of nodes of this class
      def count(distinct = nil)
        raise(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
        q = distinct.nil? ? "n" : "DISTINCT n"
        self.query_as(:n).return("count(#{q}) AS count").first.count
      end

      alias_method :size, :count
      alias_method :length, :count

      def empty?
        !self.exists?
      end

      alias_method :blank?, :empty?

      def include?(other)
        raise(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
        self.query_as(:n).where("ID(n) = #{other.neo_id}").return("count(n) AS count").first.count > 0
      end


    end
  end
end