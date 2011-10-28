module Neo4j
  module Rails
    module Versioning
      class Version
        include Neo4j::RelationshipMixin
        property :number, :type => Fixnum
        property :model_classname
        index :number
        index :model_classname
      end

      class Snapshot
        include Neo4j::NodeMixin

        def incoming(rel_type)
          super "version_#{rel_type.to_s}".to_sym
        end

        def outgoing(rel_type)
          super "version_#{rel_type.to_s}".to_sym
        end
      end

      def self.included(c)
        c.has_n(:versions).to(Snapshot).relationship(Version)
      end

      def current_version
        self[:_version] ||= 0
      end

      def version(number)
        Version.find(:model_classname => _classname, :number => number) {|query| query.first.end_node}
      end

      def revise
        Neo4j::Transaction.run do
          snapshot = Snapshot.new(self.props)
          snapshot[:_classname] = Snapshot.new[:_classname]
          version_relationships(snapshot)
          Version.new(:version, self, snapshot, :model_classname => _classname, :number => current_version)
        end
      end

      def version_relationships(snapshot)
        java_node = self._java_node
        java_node.getRelationships().each do |rel|
          if (java_node == rel.getStartNode())
            snapshot._java_node.createRelationshipTo(rel.getEndNode(), relationship_type(rel.getType()))
          else
            rel.getStartNode().createRelationshipTo(snapshot._java_node, relationship_type(rel.getType()))
          end
        end
      end

      def relationship_type(rel_type)
        org.neo4j.graphdb.DynamicRelationshipType.withName( "version_#{rel_type.name}" )
      end

      def save
        if self.changed? || self.relationships_changed?
          self[:_version] = current_version + 1
          super
          revise
        end
      end
    end
  end
end