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
          attr_accessor :model, :name, :association, :path, :rel_length

          def initialize(model, name = nil, rel_length = nil)
            super()
            self.model = name ? target_class(model, name) : model
            self.name = name
            self.association = name ? model.associations[name] : nil
            self.rel_length = rel_length
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
              process_hash(spec)
            elsif spec.is_a?(String)
              add_spec(process_string(spec))
            else
              self[spec] ||= self.class.new(model, spec)
            end
          end

          def paths(*prefix)
            values.flat_map { |v| [[*prefix, v]] + v.paths(*prefix, v) }
          end

          def process_hash(spec)
            spec.each do |k, v|
              rel_length = v.is_a?(Hash) ? v.delete(:rel_length) : nil
              (self[k] ||= self.class.new(model, k, rel_length)).add_spec(v)
            end
          end

          def process_string(spec)
            paths = spec.split(',').collect { |path| path.split('.') }
            paths.collect do |path|
              path.reverse.inject({}) do |hash, rel|
                if rel.include?('*')
                  specs = rel.split('*')
                  {specs.first.to_sym => hash.merge(rel_length: {min: 1, max: specs[1]})}
                else
                  {rel.to_sym => hash}
                end
              end
            end
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
          build_query
            .map do |record, eager_data|
            cache_and_init(record, with_associations_tree)
            eager_data.zip(with_associations_tree.paths.map(&:last)).each do |eager_records, element|
              eager_records.first.zip(eager_records.last).each do |eager_record|
                add_to_cache(*extract_rel_node(eager_record), element)
              end
            end
            record
          end
        end

        def extract_rel_node(eager_record)
          rel = eager_record.first
          node = eager_record.last
          rel = rel.last if rel.is_a?(Array)
          [rel, node]
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
          if rel.is_a?(Neo4j::ActiveRel)
            rel.instance_variable_set(direction == :in ? '@from_node' : '@to_node', node)
          end
          @_cache[direction == :out ? rel.start_node_neo_id : rel.end_node_neo_id].association_proxy(element.name).tap do |proxy|
            proxy.init_cache
            proxy.add_to_cache(node, rel)
          end
        end

        def init_associations(node, element)
          if element.rel_length && element.empty?
            node.association_proxy(element.name).init_cache
          else
            element.each_key { |key| node.association_proxy(key).init_cache }
          end
        end

        def cache_and_init(node, element)
          @_cache.add(node).tap { |n| init_associations(n, element) }
        end

        def with_associations_return_clause
          path_names.map { |n| var(n, :collection, &:itself) }.join(',')
        end

        def var(*parts)
          yield(escape(parts.compact.join('_')))
        end

        # In neo4j version 2.1.8 this fails due to a bug:
        # MATCH (`n`) WITH `n` RETURN `n`
        # but this
        # MATCH (`n`) WITH n RETURN `n`
        # and this
        # MATCH (`n`) WITH `n` AS `n` RETURN `n`
        # does not
        def var_fix(*var)
          var(*var, &method(:as_alias))
        end

        def as_alias(var)
          "#{var} AS #{var}"
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

        def build_query
          before_pluck(query_from_association_tree).pluck(identity, "[#{with_associations_return_clause}]")
        end

        def before_pluck(query)
          query_from_chain(@order_chain, query, identity)
        end

        def query_from_association_tree
          previous_with_vars = []
          with_associations_tree.paths.inject(query_as(identity).with(ensure_distinct(identity))) do |query, path|
            with_association_query_part(query, path, previous_with_vars).tap do
              previous_with_vars << var_fix(path_name(path), :collection)
            end
          end
        end

        def with_association_query_part(base_query, path, previous_with_vars)
          optional_match_with_where(base_query, path, previous_with_vars)
            .with(identity,
                  "[#{relationship_collection(path)}, collect(#{escape path_name(path)})] AS #{escape("#{path_name(path)}_collection")}",
                  *previous_with_vars)
        end

        def relationship_collection(path)
          path.last.rel_length ? "collect(relationships(#{escape("#{path_name(path)}_path")}))" : "collect(#{escape("#{path_name(path)}_rel")})"
        end

        def optional_match_with_where(base_query, path, _)
          path
            .each_with_index.map { |_, index| path[0..index] }
            .inject(optional_match(base_query, path)) do |query, path_prefix|
            query.where(path_prefix.last.association.target_where_clause(escape(path_name(path_prefix))))
          end
        end

        def optional_match(base_query, path)
          base_query.optional_match(path_cypher(path))
        end

        def path_cypher(path)
          cypher = "(#{identity})#{path.each_with_index.map do |element, index|
            relationship_part(element.association, path_name(path[0..index]), element.rel_length)
          end.join}"
          path.last.rel_length ? "#{escape("#{path_name(path)}_path")}=#{cypher}" : cypher
        end

        def relationship_part(association, path_name, rel_length)
          rel_var = rel_length ? nil : escape("#{path_name}_rel")
          "#{association.arrow_cypher(rel_var, {}, false, false, rel_length)}(#{escape(path_name)})"
        end

        def chain
          @order_chain = @chain.select { |link| link.clause == :order } unless with_associations_tree.empty?
          @chain
        end
      end
    end
  end
end
