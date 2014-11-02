module Neo4j
  module ActiveNode
    module QueryMethods
      class InvalidParameterError < StandardError; end

      def exists?(node_condition=nil)
        raise(InvalidParameterError, ':exists? only accepts ids or conditions') unless node_condition.is_a?(Fixnum) || node_condition.is_a?(Hash) || node_condition.nil?
        query_start = exists_query_start(node_condition)
        start_q = query_start.respond_to?(:query_as) ? query_start.query_as(:n) : query_start
        start_q.return("COUNT(n) AS count").first.count > 0
      end

      # Returns the first node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def first
        self.query_as(:n).limit(1).order(n: primary_key).pluck(:n).first
      end

      # Returns the last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def last
        self.query_as(:n).limit(1).order(n: {primary_key => :desc}).pluck(:n).first
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
        !self.all.exists?
      end

      alias_method :blank?, :empty?

      def include?(other)
        raise(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
        self.query_as(:n).where(n: {primary_key => other.id}).return("count(n) AS count").first.count > 0
      end

      def find_in_batches(options = {})
        self.query_as(:n).return(:n).find_in_batches(:n, primary_key, options) do |batch|
          yield batch.map(&:n)
        end
      end

      private

      def exists_query_start(node_condition)
        case node_condition
        when Fixnum
          self.query_as(:n).where("ID(n)" => node_condition)
        when Hash
          self.where(node_condition.keys.first => node_condition.values.first)
        else
          self.query_as(:n)
        end
      end
    end
  end
end
