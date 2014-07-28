module Neo4j::ActiveNode
  module IdProperty
    extend ActiveSupport::Concern
    include Neo4j::Library::IdProperty

    module ClassMethods
      def find_by_id(key, session = Neo4j::Session.current!)
        Neo4j::Node.load(key.to_i, session)
      end
    end
  end
end
