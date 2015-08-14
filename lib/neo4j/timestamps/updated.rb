module Neo4j
  module Timestamps
    # This mixin includes a updated_at timestamp property
    module Updated
      extend ActiveSupport::Concern
      included do
        property :updated_at, type: DateTime
      end
    end
  end
end
