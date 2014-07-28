module Neo4j::ActiveRel
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Library::Property

  end
end