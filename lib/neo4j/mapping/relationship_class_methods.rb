module Neo4j::Mapping
  module RelationshipClassMethods
    def decl_relationships
      # :nodoc:
      self::DECL_RELATIONSHIPS
    end

    # Specifies a relationship between two node classes.
    # Generates assignment and accessor methods for the given relationship.
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
                def #{rel_type}(&block)
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    Neo4j::Mapping::HasN.new(self, dsl, &block)
                end}, __FILE__, __LINE__)

      module_eval(%Q{
                def #{rel_type}_rels
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    Neo4j::Mapping::HasN.new(self, dsl).rels
      end}, __FILE__, __LINE__)

      decl_relationships[rel_type.to_sym] = Neo4j::Mapping::DeclRelationshipDsl.new(rel_type, params)
    end

  end
end