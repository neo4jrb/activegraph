module Neo4j
  module ActiveNode
    module Query
      module QueryProxyEagerLoading
        class IdentityMap < Hash
          def add(node)
            self[node.neo_id] ||= node
          end
        end

        class AssociationTree < Hash
          attr_accessor :model, :name, :association, :path

          def initialize(model, name = nil)
            super()
            self.model = name ? target_class(model, name) : model
            self.name = name
            self.association = name ? model.associations[name] : nil
          end

          def clone
            super.tap { |copy| copy.each { |key, value| copy[key] = value.clone } }
          end

          def add_spec(spec)
            unless model
              fail "Cannot eager load \"past\" a polymorphic association. \
              (Since the association can return multiple models, we don't how to handle the \"#{spec}\" association.)"
            end

            if spec.is_a?(Array)
              spec.each { |s| add_spec(s) }
            elsif spec.is_a?(Hash)
              spec.each { |k, v| (self[k] ||= AssociationTree.new(model, k)).add_spec(v) }
            else
              self[spec] ||= AssociationTree.new(model, spec)
            end
          end

          def paths(*prefix)
            values.flat_map { |v| [[*prefix, v]] + v.paths(*prefix, v) }
          end

          private

          def target_class(model, key)
            association = model.associations[key]
            fail "Invalid association: #{[*path, key].join('.')}" unless association
            model.associations[key].target_class
          end
        end

        def pluck_vars(node, rel)
          with_associations_tree.empty? ? super : perform_query
        end

        def perform_query
          @_cache = IdentityMap.new
          query_from_association_tree
            .map do |record, eager_data|
            cache_and_init(record, with_associations_tree)
            eager_data.zip(with_associations_tree.paths.map(&:last)).each do |eager_records, element|
              eager_records.first.zip(eager_records.last).each do |eager_record|
                add_to_cache(*eager_record, element)
              end
            end

            record
          end
        end

        def with_associations(*spec)
          new_link.tap do |new_query_proxy|
            new_query_proxy.with_associations_tree = with_associations_tree.clone
            new_query_proxy.with_associations_tree.add_spec(spec)
          end
        end

        def propagate_context(query_proxy)
          super
          query_proxy.instance_variable_set('@with_associations_tree', @with_associations_tree)
        end

        def with_associations_tree
          @with_associations_tree ||= AssociationTree.new(model)
        end

        def with_associations_tree=(tree)
          @with_associations_tree = tree
        end

        def first
          (query.clause?(:order) ? self : order(order_property)).limit(1).to_a.first
        end

        private

        def add_to_cache(rel, node, element)
          direction = element.association.direction
          node = cache_and_init(node, element)
          if rel.is_a?(Neo4j::ActiveRel)
            rel.instance_variable_set(direction == :in ? '@from_node' : '@to_node', node)
          end
          @_cache[direction == :out ? rel.start_node_neo_id : rel.end_node_neo_id]
            .association_proxy(element.name).add_to_cache(node, rel)
        end

        def init_associations(node, element)
          element.keys.each { |key| node.association_proxy(key).init_cache }
        end

        def cache_and_init(node, element)
          @_cache.add(node).tap { |n| init_associations(n, element) }
        end

        def with_associations_return_clause(variables = path_names)
          var_list(variables, &:itself)
        end

        def var_list(variables)
          variables.map { |n| yield(escape("#{n}_collection")) }.join(',')
        end

        # In neo4j version 2.1.8 this fails due to a bug:
        # MATCH (`n`) WITH `n` RETURN `n`
        # but this
        # MATCH (`n`) WITH n RETURN `n`
        # and this
        # MATCH (`n`) WITH `n` AS `n` RETURN `n`
        # does not
        def var_list_fixing_neo4j_2_1_8_bug(variables)
          var_list(variables) { |var| "#{var} AS #{var}" }
        end

        def escape(s)
          "`#{s}`"
        end

        def path_name(path)
          path.map(&:name).join('.')
        end

        def path_names
          with_associations_tree.paths.map { |path| path_name(path) }
        end

        def query_from_association_tree
          previous_with_variables = []
          no_order_query = with_associations_tree.paths.inject(query_as(identity).with(ensure_distinct(identity))) do |query, path|
            with_association_query_part(query, path, previous_with_variables).tap do
              previous_with_variables << path_name(path)
            end
          end
          query_from_chain(@order_chain, no_order_query, identity)
            .pluck(identity, "[#{with_associations_return_clause}]")
        end

        def with_association_query_part(base_query, path, previous_with_variables)
          optional_match_with_where(base_query, path)
            .with(identity,
                  "[collect(#{escape("#{path_name(path)}_rel")}), collect(#{escape path_name(path)})] AS #{escape("#{path_name(path)}_collection")}",
                  *var_list_fixing_neo4j_2_1_8_bug(previous_with_variables))
        end

        def optional_match_with_where(base_query, path)
          path
            .each_with_index.map { |_, index| path[0..index] }
            .inject(optional_match(base_query, path)) do |query, path_prefix|
            query.where(path_prefix.last.association.target_where_clause(escape(path_name(path_prefix))))
          end
        end

        def optional_match(base_query, path)
          base_query.optional_match(
            "(#{identity})#{path.each_with_index.map do |element, index|
              relationship_part(element.association, path_name(path[0..index]))
            end.join}"
          )
        end

        def relationship_part(association, path_name)
          "#{association.arrow_cypher(escape("#{path_name}_rel"))}(#{escape(path_name)})"
        end

        def chain
          @order_chain, other_chain =
            with_associations_tree.empty? ? [[], @chain] : @chain.partition { |link| link.clause == :order }
          other_chain
        end
      end
    end
  end
end
