module Neo4j::Mapping
  module ClassMethods

    module Relationship
      include Neo4j::ToJava

      # Specifies a relationship between two node classes.
      # Generates assignment and accessor methods for the given relationship.
      # Both incoming and outgoing relationships can be declared, see Neo4j::Mapping::DeclRelationshipDsl
      #
      # ==== Example
      #
      #   class FolderNode
      #      include Ne4j::NodeMixin
      #      has_n(:files)
      #   end
      #
      #   folder = FolderNode.new
      #   folder.files << Neo4j::Node.new << Neo4j::Node.new
      #   folder.files.inject {...}
      #
      # ==== Returns
      #
      # Neo4j::Mapping::DeclRelationshipDsl
      #
      def has_n(rel_type, params = {})
        clazz = self
        module_eval(%Q{
                def #{rel_type}
                    dsl = _decl_rels_for('#{rel_type}'.to_sym)
                    Neo4j::Mapping::HasN.new(self, dsl)
                end}, __FILE__, __LINE__)

        module_eval(%Q{
                def #{rel_type}_rels
                    dsl = _decl_rels_for('#{rel_type}'.to_sym)
                    dsl.all_relationships(self)
                end}, __FILE__, __LINE__)

        _decl_rels[rel_type.to_sym] = Neo4j::Mapping::DeclRelationshipDsl.new(rel_type, false, clazz, params)
      end


      # Specifies a relationship between two node classes.
      # Generates assignment and accessor methods for the given relationship
      # Old relationship is deleted when a new relationship is assigned.
      # Both incoming and outgoing relationships can be declared, see Neo4j::Mapping::DeclRelationshipDsl
      #
      # ==== Example
      #
      #   class FileNode
      #      include Ne4j::NodeMixin
      #      has_one(:folder)
      #   end
      #
      #   file = FileNode.new
      #   file.folder = Neo4j::Node.new
      #   file.folder # => the node above
      #   file.folder_rel # => the relationship object between those nodes
      #
      # ==== Returns
      #
      # Neo4j::Mapping::DeclRelationshipDsl
      #
      def has_one(rel_type, params = {})
        clazz = self
        module_eval(%Q{def #{rel_type}=(value)
                  dsl = _decl_rels_for(:#{rel_type})
                  rel = dsl.single_relationship(self)
                  rel.del unless rel.nil?
                  dsl.create_relationship_to(self, value) if value
              end}, __FILE__, __LINE__)

        module_eval(%Q{def #{rel_type}
                  dsl = _decl_rels_for(:#{rel_type})
                  dsl.single_node(self)
              end}, __FILE__, __LINE__)

        module_eval(%Q{def #{rel_type}_rel
                  # TODO - use the class variable instance since we don't want to use none persisted rails relationships
                  dsl = #{clazz}._decl_rels[:'#{rel_type.to_s}']
                  dsl.single_relationship(self)
               end}, __FILE__, __LINE__)

        _decl_rels[rel_type.to_sym] = Neo4j::Mapping::DeclRelationshipDsl.new(rel_type, true, clazz, params)
      end

    end
  end
end
