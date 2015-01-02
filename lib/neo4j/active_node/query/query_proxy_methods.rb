module Neo4j
  module ActiveNode
    module Query
      module QueryProxyMethods
        class InvalidParameterError < StandardError; end

        def first(target = nil)
          query_with_target(target) { |var| first_and_last("ID(#{var})", var) }
        end

        def last(target = nil)
          query_with_target(target) { |var| first_and_last("ID(#{var}) DESC", var) }
        end

        def first_and_last(order, target)
          self.order(order).limit(1).pluck(target).first
        end

        # @return [Fixnum] number of nodes of this class
        def count(distinct = nil, target = nil)
          fail(InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
          query_with_target(target) do |var|
            q = distinct.nil? ? var : "DISTINCT #{var}"
            self.query.reorder.pluck("count(#{q}) AS #{var}").first
          end
        end

        alias_method :size,   :count
        alias_method :length, :count

        def empty?(target = nil)
          query_with_target(target) { |var| !self.exists?(nil, var) }
        end

        alias_method :blank?, :empty?

        def include?(other, target = nil)
          fail(InvalidParameterError, ':include? only accepts nodes') unless other.respond_to?(:neo_id)
          query_with_target(target) do |var|
            self.where("ID(#{var}) = {other_node_id}").params(other_node_id: other.neo_id).query.return("count(#{var}) as count").first.count > 0
          end
        end

        def exists?(node_condition = nil, target = nil)
          fail(InvalidParameterError, ':exists? only accepts neo_ids') unless node_condition.is_a?(Fixnum) || node_condition.is_a?(Hash) || node_condition.nil?
          query_with_target(target) do |var|
            start_q = exists_query_start(node_condition, var)
            start_q.query.return("COUNT(#{var}) AS count").first.count > 0
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
            clear_caller_cache
          end
        end

        # This will match nodes who only have a single relationship of a given type.
        # It's used  by `dependent: :delete_orphans` and `dependent: :destroy_orphans` and may not have much utility otherwise.
        # @param [Neo4j::ActiveNode::HasN::Association] association The Association object used throughout the match.
        # @param [String, Symbol] other_node The identifier to use for the other end of the chain.
        # @param [String, Symbol] other_rel The identifier to use for the relationship in the optional match.
        # @return [Neo4j::ActiveNode::Query::QueryProxy]
        def unique_nodes(association, self_identifer, other_node, other_rel)
          fail 'Only supported by in QueryProxy chains started by an instance' unless caller
          both_string = "-[:`#{association.relationship_type}`]-"
          in_string = "<#{both_string}"
          out_string = "#{both_string}>"
          primary_rel, inverse_rel =  case association.direction
                                      when :out
                                        [out_string, in_string]
                                      when :in
                                        [in_string, out_string]
                                      else
                                        [both_string, both_string]
                                      end

          query.with(identity).proxy_as_optional(caller.class, self_identifer)
            .send(association.name, other_node, other_rel)
            .where("NOT EXISTS((#{self_identifer})#{primary_rel}(#{other_node})#{inverse_rel}())")
        end

        # Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id}`
        # The `node` param can be a persisted ActiveNode instance, any string or integer, or nil.
        # When it's a node, it'll use the object's neo_id, which is fastest. When not nil, it'll figure out the
        # primary key of that model. When nil, it uses `1 = 2` to prevent matching all records, which is the default
        # behavior when nil is passed to `where` in QueryProxy.
        # @param [#neo_id, String, Enumerable] node A node, a string representing a node's ID, or an enumerable of nodes or IDs.
        # @return [Neo4j::ActiveNode::Query::QueryProxy] A QueryProxy object upon which you can build.
        def match_to(node)
          where_arg = if node.respond_to?(:neo_id)
                        {neo_id: node.neo_id}
                      elsif !node.nil?
                        id_key = association_id_key
                        node = ids_array(node) if node.is_a?(Array)
                        {id_key => node}
                      else
                        # support for null object pattern
                        '1 = 2'
                      end
          self.where(where_arg)
        end

        # Gives you the first relationship between the last link of a QueryProxy chain and a given node
        # Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id} RETURN r`
        # @param [#neo_id, String, Enumerable] node An object to be sent to `match_to`. See params for that method.
        # @return A relationship (ActiveRel, CypherRelationship, EmbeddedRelationship) or nil.
        def first_rel_to(node)
          self.match_to(node).limit(1).pluck(rel_var).first
        end

        # Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.
        # @param [#neo_id, String, Enumerable] node An object to be sent to `match_to`. See params for that method.
        # @return An enumerable of relationship objects.
        def rels_to(node)
          self.match_to(node).pluck(rel_var)
        end
        alias_method :all_rels_to, :rels_to

        # Deletes the relationship between a node and its last link in the QueryProxy chain. Executed in the database, callbacks will not run.
        def delete(node)
          self.match_to(node).query.delete(rel_var).exec
          clear_caller_cache
        end

        # Returns all relationships between a node and its last link in the QueryProxy chain, destroys them in Ruby. Callbacks will be run.
        def destroy(node)
          self.rels_to(node).map!(&:destroy)
          clear_caller_cache
        end

        # A shortcut for attaching a new, optional match to the end of a QueryProxy chain.
        # TODO: It's silly that we have to call constantize here. There should be a better way of finding the target class of the destination.
        def optional(association, node_id = nil)
          target_qp = self.send(association)
          model = target_qp.name.constantize
          var = node_id || target_qp.identity
          self.query.proxy_as(model, var, true)
        end

        private

        def clear_caller_cache
          self.caller.clear_association_cache if self.caller.respond_to?(:clear_association_cache)
        end

        # @return [String] The primary key of a the current QueryProxy's model or target class
        def association_id_key
          self.association.nil? ? model.primary_key : self.association.target_class.primary_key
        end

        # @param [Enumerable] node An enumerable of nodes or ids.
        # @return [Array] An array after having `id` called on each object
        def ids_array(node)
          node.first.respond_to?(:id) ? node.map!(&:id) : node
        end

        def query_with_target(target)
          yield(target || identity)
        end

        def exists_query_start(condition, target)
          case condition
          when Fixnum
            self.where("ID(#{target}) = {exists_condition}").params(exists_condition: condition)
          when Hash
            self.where(condition.keys.first => condition.values.first)
          else
            self
          end
        end
      end
    end
  end
end
