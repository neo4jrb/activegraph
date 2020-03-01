module ActiveGraph
  module TypeConverters
    # This exists for legacy purposes. Some gems that the Neo4jrb project does not own
    # may contain references to this file. We will remove it once that has been dealt with.
    include ActiveGraph::Shared::TypeConverters
  end
end
