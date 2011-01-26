module Neo4j
  module Batch
    class BatchIndexer < Neo4j::Index::Indexer

      class << self
        def for_class(clazz)
          indexer = clazz._indexer

        end
      end
    end


  end
end