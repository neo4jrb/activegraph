module Neo4j
  module Timestamps
    # This mixin includes a updated_at timestamp property
    module Updated
      extend ActiveSupport::Concern
      included { property :updated_at }
    end
  end
end
