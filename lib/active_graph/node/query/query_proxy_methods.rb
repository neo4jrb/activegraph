module ActiveGraph
  module Node
    module Query
      # rubocop:disable Metrics/ModuleLength
      module QueryProxyMethods
        # rubocop:enable Metrics/ModuleLength
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

        def distinct
          new_link.tap do |e|
            e.instance_variable_set(:@distinct, true)
          end
        end

        def propagate_context(query_proxy)
          [:@distinct, :@rel_var].each { |var| query_proxy.instance_variable_set(var, instance_variable_get(var)) }
        end

        # @return [Integer] number of nodes of this class
        def count(distinct = nil, target = nil)
          return 0 if unpersisted_start_object?
          fail(ActiveGraph::InvalidParameterError, ':count accepts the `:distinct` symbol or nil as a parameter') unless distinct.nil? || distinct == :distinct
          query_with_target(target) do |var|
            q = ensure_distinct(var, !distinct.nil?)
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
          limit_clause = self.query.send(:clauses).find { |clause| clause.is_a?(ActiveGraph::Core::QueryClauses::LimitClause) }
          limit_clause.instance_variable_get(:@arg)
        end

        def empty?(target = nil)
          return true if unpersisted_start_object?
          query_with_target(target) { |var| !self.exists?(nil, var) }
        end

        alias blank? empty?

        # @param [ActiveGraph::Node, ActiveGraph::Node, String] other An instance of a Neo4j.rb model, a core node, or a string uuid
        # @param [String, Symbol] target An identifier of a link in the Cypher chain
        # @return [Boolean]
        def include?(other, target = nil)
          query_with_target(target) do |var|
            where_filter = if other.respond_to?(:neo_id) || association_id_key == :neo_id
                             "ID(#{var}) = $other_node_id"
                           else
                             "#{var}.#{association_id_key} = $other_node_id"
                           end
            node_id = other.respond_to?(:neo_id) ? other.neo_id : other
            self.where(where_filter).params(other_node_id: node_id).query.reorder.return("count(#{var}) as count")
                .first[:count].positive?
          end
        end

        def exists?(node_condition = nil, target = nil)
          unless [Integer, String, Hash, NilClass].any? { |c| node_condition.is_a?(c) }
            fail(ActiveGraph::InvalidParameterError, ':exists? only accepts ids or conditions')
          end
          query_with_target(target) do |var|
            start_q = exists_query_start(node_condition, var)
            result = start_q.query.reorder.return("ID(#{var}) AS proof_of_life LIMIT 1").first
            !!result
          end
        end

        # Shorthand for `MATCH (start)-[r]-(other_node) WHERE ID(other_node) = #{other_node.neo_id}`
        # The `node` param can be a persisted Node instance, any string or integer, or nil.
        # When it's a node, it'll use the object's neo_id, which is fastest. When not nil, it'll figure out the
        # primary key of that model. When nil, it uses `1 = 2` to prevent matching all records, which is the default
        # behavior when nil is passed to `where` in QueryProxy.
        # @param [#neo_id, String, Enumerable] node A node, a string representing a node's ID, or an enumerable of nodes or IDs.
        # @return [ActiveGraph::Node::Query::QueryProxy] A QueryProxy object upon which you can build.
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
        # @return A relationship (Relationship, CypherRelationship, EmbeddedRelationship) or nil.
        def first_rel_to(node)
          self.match_to(node).limit(1).pluck(rel_var).first
        end

        # Returns all relationships across a QueryProxy chain between a given node or array of nodes and the preceeding link.
        # @param [#neo_id, String, Enumerable] node An object to be sent to `match_to`. See params for that method.
        # @return An enumerable of relationship objects.
        def rels_to(node)
          self.match_to(node).pluck(rel_var)
        end
        alias all_rels_to rels_to

        # When called, this method returns a single node that satisfies the match specified in the params hash.
        # If no existing node is found to satisfy the match, one is created or associated as expected.
        def find_or_create_by(params)
          fail 'Method invalid when called on Class objects' unless source_object
          result = self.where(params).first
          return result unless result.nil?
          ActiveGraph::Base.transaction do
            node = model.create(params)
            self << node
            node
          end
        end

        def find_or_initialize_by(attributes, &block)
          find_by(attributes) || initialize_by_current_chain_params(attributes, &block)
        end

        def first_or_initialize(attributes = {}, &block)
          first || initialize_by_current_chain_params(attributes, &block)
        end

        # A shortcut for attaching a new, optional match to the end of a QueryProxy chain.
        def optional(association, node_var = nil, rel_var = nil)
          self.send(association, node_var, rel_var, optional: true)
        end

        # Takes an Array of Node models and applies the appropriate WHERE clause
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

        # Matches all nodes having at least a relation
        #
        # @example Load all people having a friend
        #   Person.all.having_rel(:friends).to_a # => Returns a list of `Person`
        #
        # @example Load all people having a best friend
        #   Person.all.having_rel(:friends, best: true).to_a # => Returns a list of `Person`
        #
        # @return [QueryProxy] A new QueryProxy
        def having_rel(association_name, rel_properties = {})
          association = association_or_fail(association_name)
          where("(#{identity})#{association.arrow_cypher(nil, rel_properties)}()")
        end

        # Matches all nodes not having a certain relation
        #
        # @example Load all people not having friends
        #   Person.all.not_having_rel(:friends).to_a # => Returns a list of `Person`
        #
        # @example Load all people not having best friends
        #   Person.all.not_having_rel(:friends, best: true).to_a # => Returns a list of `Person`
        #
        # @return [QueryProxy] A new QueryProxy
        def not_having_rel(association_name, rel_properties = {})
          association = association_or_fail(association_name)
          where_not("(#{identity})#{association.arrow_cypher(nil, rel_properties)}()")
        end

        private

        def association_or_fail(association_name)
          model.associations[association_name] || fail(ArgumentError, "No such association #{association_name}")
        end

        def find_inverse_association!(model, source, association)
          model.associations.values.find do |reverse_association|
            association.inverse_of?(reverse_association) ||
              reverse_association.inverse_of?(association) ||
              inverse_relation_of?(source, association, model, reverse_association)
          end || fail("Could not find reverse association for #{@context}")
        end

        def inverse_relation_of?(source, source_association, target, target_association)
          source_association.direction != target_association.direction &&
            source == target_association.target_class &&
            target == source_association.target_class &&
            source_association.relationship_class_name == target_association.relationship_class_name
        end

        def initialize_by_current_chain_params(params = {})
          result = new(where_clause_params.merge(params))

          inverse_association = find_inverse_association!(model, source_object.class, association) if source_object
          result.tap do |m|
            yield(m) if block_given?
            m.public_send(inverse_association.name) << source_object if inverse_association
          end
        end

        def where_clause_params
          query.clauses.select { |c| c.is_a?(ActiveGraph::Core::QueryClauses::WhereClause) && c.arg.is_a?(Hash) }
               .map! { |e| e.arg[identity] }.compact.inject { |a, b| a.merge(b) } || {}
        end

        def first_and_last(func, target)
          new_query, pluck_proc = if self.query.clause?(:order)
                                    [self.query.with(identity),
                                     proc { |var| "#{func}(COLLECT(#{var})) as #{var}" }]
                                  else
                                    ord_prop = (func == LAST ? {order_property => :DESC} : order_property)
                                    [self.order(ord_prop).limit(1),
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
            self.where("ID(#{target}) = $exists_condition").params(exists_condition: condition)
          when Hash
            self.where(condition.keys.first => condition.values.first)
          when String
            self.where(model.primary_key => condition)
          else
            self
          end
        end
      end
    end
  end
end
