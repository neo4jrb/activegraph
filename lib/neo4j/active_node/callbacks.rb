module Neo4j
  module ActiveNode
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern
      include Neo4j::Shared::Callbacks
    end
  end
end
