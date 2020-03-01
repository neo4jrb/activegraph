require 'active_graph/timestamps/created'
require 'active_graph/timestamps/updated'

module ActiveGraph
  # This mixin includes timestamps in the included class
  module Timestamps
    extend ActiveSupport::Concern
    include Created
    include Updated
  end
end
