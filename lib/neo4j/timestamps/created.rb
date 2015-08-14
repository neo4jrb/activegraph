module Neo4j
  module Timestamps
    # This mixin includes a created_at timestamp property
    module Created
      extend ActiveSupport::Concern
      included do
        property :created_at, type: DateTime
      end
    end
  end
end
