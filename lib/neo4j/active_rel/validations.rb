module Neo4j
  module ActiveRel
    module Validations
      extend ActiveSupport::Concern
      include Neo4j::Shared::Validations
    end
  end
end
