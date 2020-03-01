module ActiveGraph
  module Node
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern
      include ActiveGraph::Shared::Callbacks
    end
  end
end
