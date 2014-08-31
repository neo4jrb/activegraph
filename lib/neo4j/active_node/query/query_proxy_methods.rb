module Neo4j
  module ActiveNode
    module Query
      module QueryProxyMethods
        class InvalidParameterError < StandardError; end

        def query_target(target)
          target.nil? ? identity : target
        end

        def first(target=nil)
          target = query_target(target)
          self.order("ID(#{target})").limit(1).pluck(target).first
        end

        def last(target=nil)
          target = query_target(target)
          self.order("ID(#{target}) DESC").limit(1).pluck(target).first
        end

        # @return [Fixnum] number of nodes of this class
        def count(distinct=nil, target=nil)
          raise(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
          target = query_target(target)
          q = distinct.nil? ? target : "DISTINCT #{target}"
          self.query.return("count(#{q}) AS count").first.count
        end
        alias_method :size,   :count
        alias_method :length, :count

        def empty?(target=nil)
          target = query_target(target)
          !self.exists?(nil, target)
        end
        alias_method :blank?, :empty?

        def include?(other, target=nil)
          raise(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
          target = query_target(target)
          self.where("ID(#{target}) = {other_node_id}").params(other_node_id: other.neo_id).query.return("count(#{target}) AS count").first.count > 0
        end

        def exists?(node_id=nil, target=nil)
          raise(InvalidParameterError, ':exists? only accepts neo_ids') unless node_id.is_a?(Integer) || node_id.nil?
          target = query_target(target)
          start_q = self.query
          end_q = node_id.nil? ? start_q : start_q.where("ID(#{target}) = #{node_id}")
          end_q.return("COUNT(#{target}) AS count").first.count > 0
        end
      end
    end
  end
end