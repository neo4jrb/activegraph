# frozen_string_literal: true

module ActiveGraph
  module StringParsers
    # Filtering relationships with length
    class RelationParser < ::Parslet::Parser
      rule(:asterix)   { str('*') }
      rule(:digit)     { match('[\d]').repeat }
      rule(:range)     { str('..') }
      rule(:dot)       { str('.') }
      rule(:zero)      { str('0') }
      rule(:length_1)  { zero.as(:min) >> range >> digit.maybe.as(:max) }
      rule(:length_2)  { digit.maybe.as(:max) }
      rule(:length)    { asterix >> (length_1 | length_2) }
      rule(:rel)       { match('[a-z,_]').repeat.as(:rel_name) }
      rule(:key)       { rel >> length.maybe.as(:length_part) }
      rule(:anything)  { match('.').repeat }
      rule(:root) { key >> dot.maybe >> anything.maybe.as(:rest_str) }
    end
  end
end
