module Neo4j
  module ActiveNode
    module Query
      module QueryProxyMethods
        class InvalidParameterError < StandardError; end

        def query_with_target(target, &block)
          target = target.nil? ? identity : target
          block.yield(target)
        end

        def first(target=nil)
          query_with_target(target) { |target| first_and_last("ID(#{target})", target) }
        end

        def last(target=nil)
          query_with_target(target) { |target| first_and_last("ID(#{target}) DESC", target) }
        end

        def first_and_last(order, target)
          self.order(order).limit(1).pluck(target).first
        end

        # @return [Fixnum] number of nodes of this class
        def count(distinct=nil, target=nil)
          raise(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
          query_with_target(target) do |target|
            q = distinct.nil? ? target : "DISTINCT #{target}"
            self.query.return("count(#{q}) AS count").first.count
          end
        end

        alias_method :size,   :count
        alias_method :length, :count

        def empty?(target=nil)
          query_with_target(target) { |target| !self.exists?(nil, target) }
        end

        alias_method :blank?, :empty?

        def include?(other, target=nil)
          raise(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
          query_with_target(target) do |target|
            self.where("ID(#{target}) = {other_node_id}").params(other_node_id: other.neo_id).query.return("count(#{target}) AS count").first.count > 0
          end
        end

        def exists?(node_id=nil, target=nil)
          raise(InvalidParameterError, ':exists? only accepts neo_ids') unless node_id.is_a?(Integer) || node_id.nil?
          query_with_target(target) do |target|
            start_q = self.query
            end_q = node_id.nil? ? start_q : start_q.where("ID(#{target}) = #{node_id}")
            end_q.return("COUNT(#{target}) AS count").first.count > 0
          end
        end
      end
    end
  end
end