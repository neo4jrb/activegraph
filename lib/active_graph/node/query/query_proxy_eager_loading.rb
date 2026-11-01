module ActiveGraph
  module Node
    module Query
      module QueryProxyEagerLoading
        class IdentityMap < Hash
          def add(node)
            self[node.neo_id] ||= node
          end
        end

        def pluck_vars(node, rel)
          with_associations_tree.empty? ? super : perform_query
        end

        def perform_query
          @_cache = IdentityMap.new
          build_query
            .map do |record, eager_data|
            record = cache_and_init(record, with_associations_tree)
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
          @with_associations_tree ||= association_tree_class.new(model)
        end

        def association_tree_class
          AssociationTree
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
          if rel.is_a?(ActiveGraph::Relationship)
            rel.instance_variable_set(direction == :in ? '@from_node' : '@to_node', node)
          end
          @_cache[direction == :out ? rel.start_node_element_id : rel.end_node_element_id]
            .association_proxy(element.name).add_to_cache(node, rel)
        end

        def init_associations(node, element)
          element.each_key { |key| node.association_proxy(key).init_cache }
          node.association_proxy(element.name).init_cache if element.rel_length && element.rel_length[:max] == ''
        end

        def cache_and_init(node, element)
          @_cache.add(node).tap { |n| init_associations(n, element) }
        end

        # The variables of one path: the node, its relationship, the named path and the collection of
        # relationship/node pairs handed on from WITH to WITH.
        def path_name(path)
          path.map(&:name).join('.')
        end

        def path_node(path)
          CypherDSL::Cypher.any_node(path_name(path))
        end

        def path_names
          with_associations_tree.paths.map { |path| path_name(path) }
        end

        def collection_name(path)
          CypherDSL::Cypher.name("#{path_name(path)}_collection")
        end

        def build_query
          collections = with_associations_tree.paths.map { |path| collection_name(path) }
          before_pluck(query_from_association_tree).pluck(identity, CypherDSL::Cypher.list_of(*collections))
        end

        def before_pluck(query)
          query_from_chain(@order_chain, query, identity)
        end

        def query_from_association_tree
          previous_collections = []
          with_method = @distinct ? :with_distinct : :with
          start_query = query_as(identity).send(with_method, identity)
          with_associations_tree.paths.inject(start_query) do |query, path|
            with_association_query_part(query, path, previous_collections).tap do
              previous_collections << collection_name(path)
            end
          end
        end

        def with_association_query_part(base_query, path, previous_collections)
          nodes = CypherDSL::Cypher.collect(path_node(path))
          pairs = CypherDSL::Cypher.list_of(relationship_collection(path), nodes)
          optional_match_with_where(base_query, path)
            .with(identity, pairs.as(collection_name(path)), *previous_collections)
        end

        # `collect(rel)`, or the last relationship of each path for a variable-length association.
        def relationship_collection(path)
          if path.last.rel_length
            path = CypherDSL::Cypher.name("#{path_name(path)}_path")
            CypherDSL::Cypher.collect(CypherDSL::Cypher.last(CypherDSL::Cypher.relationships(path)))
          else
            CypherDSL::Cypher.collect(CypherDSL::Cypher.name("#{path_name(path)}_rel"))
          end
        end

        def optional_match_with_where(base_query, path)
          path.each_index.map { |index| path[0..index] }.inject(optional_match(base_query, path)) do |query, path_prefix|
            condition = path_prefix.last.association.target_condition(path_name(path_prefix))
            condition ? query.where(condition) : query
          end
        end

        # `OPTIONAL MATCH path = (identity)-[rel]->(node)-[…]->(…)`, one hop per element of the path.
        def optional_match(base_query, path)
          pattern = path.each_index.inject(CypherDSL::Cypher.any_node(identity)) do |left, index|
            element = path[index]
            rel_name = "#{path_name(path[0..index])}_rel" unless element.rel_length
            element.association.relationship_pattern(left, path_node(path[0..index]), var: rel_name, length: element.rel_length)
          end
          base_query.optional_match(CypherDSL::Cypher.path("#{path_name(path)}_path").defined_by(pattern))
        end

        def chain
          @order_chain = @chain.select { |link| link.clause == :order } unless with_associations_tree.empty?
          @chain
        end
      end
    end
  end
end
