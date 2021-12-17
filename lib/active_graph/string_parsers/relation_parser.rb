# frozen_string_literal: true

module ActiveGraph
  module StringParsers
    # Filtering relationships with length
    class RelationParser < ::Parslet::Parser
      rule(:asterix)   { str('*') }
      rule(:digit)     { match('[\d]').repeat }
      rule(:range)     { str('..') }
      rule(:dot)       { str('.') }
      rule(:length)    { asterix >> digit.maybe.as(:min) >> range.maybe >> digit.maybe.as(:max) }
      rule(:rel)       { match('[a-z,_]').repeat.as(:rel_name) }
      rule(:key)       { rel >> length.maybe.as(:length_part) }
      rule(:anything)  { match('.+') }
      rule(:root) { key >> dot.maybe >> anything.maybe.as(:rest_str) }
    end
  end
end
