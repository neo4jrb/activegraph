require 'neo4j/timestamps/created'
require 'neo4j/timestamps/updated'

module Neo4j
  # This mixin includes timestamps in the included class
  module Timestamps
    extend ActiveSupport::Concern
    include Created
    include Updated
  end
end
