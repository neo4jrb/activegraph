module Neo4j
  module ActiveNode
    module Query
      module QueryProxyEagerLoading
        def each(node = true, rel = nil, &block)
          return super if with_associations_spec.size.zero?

          query_from_association_spec.pluck(identity, "[#{with_associations_return_clause}]").map do |record, eager_data|
            eager_data.each_with_index do |eager_records, index|
              record.association_proxy(with_associations_spec[index]).cache_result(eager_records)
            end

            block.call(record)
          end
        end

        def with_associations_spec
          @with_associations_spec ||= []
        end

        def with_associations(*spec)
          invalid_association_names = spec.reject do |association_name|
            model.associations[association_name]
          end

          if invalid_association_names.size > 0
            fail "Invalid associations: #{invalid_association_names.join(', ')}"
          end

          new_link.tap do |new_query_proxy|
            new_spec = new_query_proxy.with_associations_spec + spec
            new_query_proxy.with_associations_spec.replace(new_spec)
          end
        end

        private

        def with_associations_return_clause(variables = with_associations_spec)
          variables.map { |n| "#{n}_collection" }.join(',')
        end

        def query_from_association_spec
          previous_with_variables = []
          with_associations_spec.inject(query_as(identity).with(identity)) do |query, association_name|
            with_association_query_part(query, association_name, previous_with_variables).tap do
              previous_with_variables << association_name
            end
          end.return(identity)
        end

        def with_association_query_part(base_query, association_name, previous_with_variables)
          association = model.associations[association_name]

          base_query.optional_match("(#{identity})#{association.arrow_cypher}(#{association_name})")
            .where(association.target_where_clause)
            .with(identity, "collect(#{association_name}) AS #{association_name}_collection", *with_associations_return_clause(previous_with_variables))
        end
      end
    end
  end
end
