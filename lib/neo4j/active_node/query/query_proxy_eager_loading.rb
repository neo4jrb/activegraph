module Neo4j
  module ActiveNode
    module Query
      module QueryProxyEagerLoading
        def with_associations(*spec)
          return_object_clause = '[' + spec.map { |n| "collect(#{n})" }.join(',') + ']'
          query_from_association_spec(spec).pluck(:previous, return_object_clause).map do |record, eager_data|
            eager_data.each_with_index do |eager_records, index|
              record.association_proxy(spec[index]).cache_result(eager_records)
            end

            record
          end
        end

        private

        def query_from_association_spec(spec)
          spec.inject(query_as(:previous).return(:previous)) do |query, association_name|
            association = model.associations[association_name]
            where_clause = unless association.model_class == false
              Array.new(association.target_classes).map do |target_class|
                "#{association_name}:#{target_class.mapped_label_name}"
              end.join(' OR ')
            end
            query.optional_match("previous#{association.arrow_cypher}#{association_name}").where(where_clause)
          end
        end
      end
    end
  end
end
