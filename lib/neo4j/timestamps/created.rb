module Neo4j
  module Timestamps
    # This mixin includes a created_at timestamp property
    module Created
      extend ActiveSupport::Concern
      included { property :created_at }
    end
  end
end
