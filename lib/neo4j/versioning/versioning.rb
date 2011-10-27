module Neo4j
  class Version
    include Neo4j::RelationshipMixin
    property :number, :type => Fixnum
    property :classname
    index :number
    index :classname
  end

  class Snapshot
    include Neo4j::NodeMixin
  end

  module Versioning

    def self.included(c)
      c.has_n(:version).to(Snapshot).relationship(Version)
    end

    def current_version
      self[:_version] = 0 if self[:_version].nil?
      self[:_version]
    end

    def version(number)
      Version.find(:classname => _classname, :number => number) {|query| query.first.end_node}
    end

    def revise
      self[:_version] = current_version + 1
      Neo4j::Transaction.run do
        snapshot = Snapshot.new(self.props)
        version_relationships(snapshot)
        Version.new(:version, self, snapshot, :classname => _classname, :number => current_version)
      end
    end

    def version_relationships(snapshot)
      java_node = self._java_node
      java_node.getRelationships().each do |java_rel|
        if (java_node == java_rel.getStartNode())
          snapshot._java_node.createRelationshipTo(java_rel.getOtherNode(java_node),java_rel.getType())
        else
          java_rel.getStartNode().createRelationshipTo(java_node,java_rel.getType())
        end
      end
    end

    #Move this out to another module
    def save
      super
      revise
    end
  end
end