module ActiveGraph
  module Node
    module Query
      module QueryProxyFindInBatches
        def find_in_batches(options = {})
          query.return(identity).find_in_batches(identity, @model.primary_key, options) do |batch|
            yield batch.map { |record| record[identity] }
          end
        end

        def find_each(options = {})
          query.return(identity).find_each(identity, @model.primary_key, options) do |result|
            yield result[identity]
          end
        end
      end
    end
  end
end
