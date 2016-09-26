module Neo4j
  module ActiveNode
    module Query
      module QueryProxyMethods
        FIRST = 'HEAD'
        LAST = 'LAST'

        def rels
          fail 'Cannot get rels without a relationship variable.' if !@rel_var

          pluck(@rel_var)
        end

        def rel
          rels.first
        end

        def as(node_var)
          new_link(node_var)
        end

        # Give ability to call `#find` on associations to get a scoped find
        # Doesn't pass through via `method_missing` because Enumerable has a `#find` method
        def find(*args)
          scoping { @model.find(*args) }
        end

        def first(target = nil)
          first_and_last(FIRST, target)
        end

        def last(target = nil)
          first_and_last(LAST, target)
        end

        def order_property
          # This should maybe be based on a setting in the association
          # rather than a hardcoded `nil`
          model ? model.id_property_name : nil
        end

        # @return [Integer] number of nodes of this class
        def count(distinct = nil, target = nil)
          fail(Neo4j::InvalidParameterError, ':count accepts `distinct` or nil as a parameter') unless distinct.nil? || distinct == :distinct
          query_with_target(target) do |var|
            q = distinct.nil? ? var : "DISTINCT #{var}"
            limited_query = self.query.clause?(:limit) ? self.query.break.with(var) : self.query.reorder
            limited_query.pluck("count(#{q}) AS #{var}").first
          end
        end

        def size
          result_cache? ? result_cache_for.length : count
        end

        delegate :length, to: :to_a

        # TODO: update this with public API methods if/when they are exposed
        def limit_value
          return unless self.query.clause?(:limit)
          limit_clause = self.query.send(:clauses).find { |clause| clause.is_a?(Neo4j::Core::QueryClauses::LimitClause) }
          limit_clause.instance_variable_get(:@arg)
        end

        def empty?(target = nil)
          query_with_target(target) { |var| !self.exists?(nil, var) }
        end

        alias_method :blank?, :empty?

        # @param [Neo4j::ActiveNode, Neo4j::Node, String] other An instance of a Neo4j.rb model, a Neo4j-core node, or a string uuid
        # @param [String, Symbol] target An identifier of a link in the Cypher chain
        # @return [Boolean]
        def include?(other, target = nil)
          query_with_target(target) do |var|
            where_filter = if other.respond_to?(:neo_id)
                             "ID(#{var}) = {other_node_id}"
                           else
                             "#{var}.#{association_id_key} = {other_node_id}"
                           end
            node_id = other.respond_to?(:neo_id) ? other.neo_id : other
            self.where(where_filter).params(other_node_id: node_id).query.reorder.return("count(#{var}) as count").first.count > 0
          end
        end

        def exists?(node_condition = nil, target = nil)
          unless node_condition.is_a?(Integer) || node_condition.is_a?(Hash) || node_condition.nil?
            fail(Neo4j::InvalidParameterError, ':exists? only accepts neo_ids')
          end
          query_with_target(target) do |var|
            start_q = exists_query_start(node_condition, var)
            start_q.query.reorder.return("COUNT(#{var}) AS count").first.count > 0
          end
        end

        # Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id}`
        # The `node` param can be a persisted ActiveNode instance, any string or integer, or nil.
        # When it's a node, it'll use the object's neo_id, which is fastest. When not nil, it'll figure out the
        # primary key of that model. When nil, it uses `1 = 2` to prevent matching all records, which is the default
        # behavior when nil is passed to `where` in QueryProxy.
        # @param [#neo_id, String, Enumerable] node A node, a string representing a node's ID, or an enumerable of nodes or IDs.
        # @return [Neo4j::ActiveNode::Query::QueryProxy] A QueryProxy object upon which you can build.
        def match_to(node)
          first_node = node.is_a?(Array) ? node.first : node
          where_arg = if first_node.respond_to?(:neo_id)
                        {neo_id: node.is_a?(Array) ? node.map(&:neo_id) : node}
                      elsif !node.nil?
                        {association_id_key => node.is_a?(Array) ? ids_array(node) : node}
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

        # When called, this method returns a single node that satisfies the match specified in the params hash.
        # If no existing node is found to satisfy the match, one is created or associated as expected.
        def find_or_create_by(params)
          fail 'Method invalid when called on Class objects' unless source_object
          result = self.where(params).first
          return result unless result.nil?
          Neo4j::Transaction.run do
            node = model.find_or_create_by(params)
            self << node
            return node
          end
        end

        # A shortcut for attaching a new, optional match to the end of a QueryProxy chain.
        def optional(association, node_var = nil, rel_var = nil)
          self.send(association, node_var, rel_var, optional: true)
        end

        # Takes an Array of ActiveNode models and applies the appropriate WHERE clause
        # So for a `Teacher` model inheriting from a `Person` model and an `Article` model
        # if you called .as_models([Teacher, Article])
        # The where clause would look something like:
        #
        # .. code-block:: cypher
        #
        #   WHERE (node_var:Teacher:Person OR node_var:Article)
        def as_models(models)
          where_clause = models.map do |model|
            "`#{identity}`:" + model.mapped_label_names.map do |mapped_label_name|
              "`#{mapped_label_name}`"
            end.join(':')
          end.join(' OR ')

          where("(#{where_clause})")
        end

        private

        def first_and_last(func, target)
          new_query, pluck_proc = if self.query.clause?(:order)
                                    [self.query.with(identity),
                                     proc { |var| "#{func}(COLLECT(#{var})) as #{var}" }]
                                  else
                                    [self.order(order_property).limit(1),
                                     proc { |var| var }]
                                  end
          query_with_target(target) do |var|
            final_pluck = pluck_proc.call(var)
            new_query.pluck(final_pluck)
          end.first
        end

        # @return [String] The primary key of a the current QueryProxy's model or target class
        def association_id_key
          self.association.nil? ? model.primary_key : self.association.target_class.primary_key
        end

        # @param [Enumerable] node An enumerable of nodes or ids.
        # @return [Array] An array after having `id` called on each object
        def ids_array(node)
          node.first.respond_to?(:id) ? node.map(&:id) : node
        end

        def query_with_target(target)
          yield(target || identity)
        end

        def exists_query_start(condition, target)
          case condition
          when Integer
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
