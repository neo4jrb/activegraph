# Used to aggregate property values.
#
# :api: private
class Neo4j::Aggregate::PropertyEnum #:nodoc:
  include Enumerable

  def initialize(nodes, property)
    @nodes = nodes
    @property = property
  end

  def each
    @nodes.each do |n|
      v = n[@property]
      if v.kind_of?(Enumerable)
        v.each {|vv| yield vv}
      else
        yield v
      end
    end

  end

end
