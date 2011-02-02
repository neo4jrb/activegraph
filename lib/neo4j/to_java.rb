module Neo4j
  module ToJava

    def type_to_java(type)
      org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
    end

    def type_from_java(type)
      type.get_type
    end

    def dir_from_java(dir)
      case dir
        when org.neo4j.graphdb.Direction::OUTGOING then :outgoing
        when org.neo4j.graphdb.Direction::BOTH     then :both
        when org.neo4j.graphdb.Direction::INCOMING then :incoming
        else raise "unknown direction '#{dir} / #{dir.class}'"
      end
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


#org.neo4j.kernel.impl.core.IntArrayIterator.class_eval do
#  def each_wrapped #:nodoc:
#    while(hasNext())
#      yield self.next().wrapper
#    end
#  end
#
#  def wrapped #:nodoc:
#    Enumerator.new(self, :each_wrapped)
#  end
#
#end
