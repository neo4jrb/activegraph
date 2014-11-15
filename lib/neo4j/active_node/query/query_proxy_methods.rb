module Neo4j
  module ActiveNode
    module Query
      module QueryProxyMethods
        class InvalidParameterError < StandardError; end

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
            self.query.pluck("count(#{q}) AS #{target}").first
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
            self.where("ID(#{target}) = {other_node_id}").params(other_node_id: other.neo_id).query.return("count(#{target}) as count").first.count > 0
          end
        end

        def exists?(node_condition=nil, target=nil)
          raise(InvalidParameterError, ':exists? only accepts neo_ids') unless node_condition.is_a?(Fixnum) || node_condition.is_a?(Hash) || node_condition.nil?
          query_with_target(target) do |target|
            start_q = exists_query_start(self, node_condition, target)
            start_q.query.return("COUNT(#{target}) AS count").first.count > 0
          end
        end

        # Deletes a group of nodes and relationships within a QP chain. When identifier is omitted, it will remove the last link in the chain.
        # The optional argument must be a node identifier. A relationship identifier will result in a Cypher Error
        # @param [String,Symbol] the optional identifier of the link in the chain to delete.
        def delete_all(identifier = nil)
          query_with_target(identifier) do |target|
            begin
              self.query.with(target).match("(#{target})-[#{target}_rel]-()").delete("#{target}, #{target}_rel").exec
            rescue Neo4j::Session::CypherError
              self.query.delete(target).exec
            end
            self.caller.clear_association_cache if self.caller.respond_to?(:clear_association_cache)
          end
        end

        # Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id}`
        # @return [Neo4j::ActiveNode::Query::QueryProxy] A QueryProxy object upon which you can build.
        def match_to(node)
          self.where(neo_id: node.neo_id)
        end

        # Gives you the first relationship between the last link of a QueryProxy chain and a given node
        # Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id} RETURN r`
        def first_rel_to(node)
          self.where(neo_id: node.neo_id).limit(1).pluck(rel_identity).first
        end

        private

        def query_with_target(target, &block)
          block.yield(target || identity)
        end

        def exists_query_start(origin, condition, target)
          case
          when condition.class == Fixnum
            self.where("ID(#{target}) = {exists_condition}").params(exists_condition: condition)
          when condition.class == Hash
            self.where(condition.keys.first => condition.values.first)
          else
            self
          end
        end
      end
    end
  end
end
