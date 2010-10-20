module Neo4j
  module ToJava

    def type_to_java(type)
      org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
    end

    def dir_to_java(dir)
      case dir
        when :outgoing then org.neo4j.graphdb.Direction::OUTGOING
        when :both     then org.neo4j.graphdb.Direction::BOTH
        when :incoming then org.neo4j.graphdb.Direction::INCOMING
        else raise "unknown direction '#{dir}', expects :outgoing, :incoming or :both"
      end
    end
  end
end


org.neo4j.kernel.impl.core.IntArrayIterator.class_eval do
  def each_wrapped
    while(hasNext())
      yield self.next().wrapper
    end
  end

  def wrapped
    Enumerator.new(self, :each_wrapped)
  end

end
