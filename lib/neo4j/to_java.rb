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