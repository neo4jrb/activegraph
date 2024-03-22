module ActiveGraph
  module Node
    module QueryMethods
      def exists?(node_condition = nil)
        unless [Integer, String, Hash, NilClass].any? { |c| node_condition.is_a?(c) }
          fail(ActiveGraph::InvalidParameterError, ':exists? only accepts ids or conditions')
        end
        query_start = exists_query_start(node_condition)
        start_q = query_start.respond_to?(:query_as) ? query_start.query_as(:n) : query_start
        result = start_q.return('ID(n) AS proof_of_life LIMIT 1').first
        !!result
      end

      # Returns the first node (or first N nodes if a parameter is supplied) of this class, sorted by ID.
      # Note that this may not be the first node created since Neo4j recycles IDs.
      def first(limit = 1)
        find_nth(0, limit)
      end

      # Returns the last node (or last N nodes if a parameter is supplied) of this class, sorted by ID.
      # Note that this may not be the first node created since Neo4j recycles IDs.
      def last(limit = 1)
        find_nth_from_last(0, limit)
      end

      # Returns the second node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def second
        find_nth(1)
      end

      # Returns the third node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def third
        find_nth(2)
      end

      # Returns the fourth node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def fourth
        find_nth(3)
      end

      # Returns the fifth node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def fifth
        find_nth(4)
      end

      # Returns the third to last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def third_to_last
        find_nth_from_last(2)
      end

      # Returns the second to last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def second_to_last
        find_nth_from_last(1)
      end

      # @return [Integer] number of nodes of this class
      def count(distinct = nil)
        fail(ActiveGraph::InvalidParameterError, ':count accepts the `:distinct` symbol or nil as a parameter') unless distinct.nil? || distinct == :distinct
        q = distinct.nil? ? 'n' : 'DISTINCT n'
        self.query_as(:n).return("count(#{q}) AS count").first[:count]
      end

      alias size count
      alias length count

      def empty?
        !self.all.exists?
      end

      alias blank? empty?

      def find_in_batches(options = {})
        self.query_as(:n).return(:n).find_in_batches(:n, primary_key, options) do |batch|
          yield batch.map { |record| record[:n] }
        end
      end

      def find_each(options = {})
        self.query_as(:n).return(:n).find_each(:n, primary_key, options) do |batch|
          yield batch[:n]
        end
      end

      private

      def exists_query_start(node_condition)
        case node_condition
        when Integer
          self.query_as(:n).where('ID(n)' => node_condition)
        when String
          self.query_as(:n).where(n: {primary_key => node_condition})
        when Hash
          self.where(node_condition.keys.first => node_condition.values.first)
        else
          self.query_as(:n)
        end
      end

      def find_nth(index, limit = 1, order = primary_key)
        if limit == 1
          self.query_as(:n).order(n: order).limit(limit).skip(index).pluck(:n).first
        else
          self.query_as(:n).order(n: order).limit(limit).skip(index).pluck(:n).first(limit)
        end
      end

      def find_nth_from_last(index, limit = 1)
        find_nth(index, limit, {primary_key => :desc})
      end
    end
  end
end
