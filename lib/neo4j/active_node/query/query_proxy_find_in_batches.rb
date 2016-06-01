module Neo4j
  module ActiveNode
    module Query
      module QueryProxyFindInBatches
        def find_in_batches(options = {})
          query.return(identity).find_in_batches(identity, @model.primary_key, options) do |batch|
            yield batch.map(&identity)
          end
        end

        def find_each(options = {})
          query.return(identity).find_each(identity, @model.primary_key, options) do |result|
            yield result.send(identity)
          end
        end
      end
    end
  end
end
