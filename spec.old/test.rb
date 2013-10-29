require 'spec_helper'

class Foo
  include Neo4j::NodeMixin
end

class Bar < Foo

end

puts "BAR #{Bar._indexer}"