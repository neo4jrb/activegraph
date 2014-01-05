module Neo4j::ActiveNode
  module HasN
    extend ActiveSupport::Concern

    def _decl_rels_for(rel_type)
      self.class._decl_rels[rel_type]
    end

    module ClassMethods

      def _decl_rels
        @_decl_rels ||= {}
      end

      # make sure the inherited classes inherit the <tt>_decl_rels</tt> hash
      def inherited(klass)
        copy = _decl_rels.clone
        copy.each_pair{|k,v| copy[k] = v.inherit_new}
        klass.instance_variable_set(:@_decl_rels, copy)
        super
      end


      # Specifies a relationship between two node active node classes.
      # Generates assignment and accessor methods for the given relationship.
      # Both incoming and outgoing relationships can be declared, see {Neo4j::ActiveNode::HasN::DeclRel}
      #
      # @example has_n(:files)
      #
      #   class FolderNode
      #      include Neo4j::ActiveNode
      #      has_n(:files)
      #   end
      #
      #   folder = FolderNode.new
      #   folder.files << Neo4j::Node.new << Neo4j::Node.new
      #   folder.files.inject {...}
      #
      #   FolderNode.files #=> 'files' the name of the relationship
      #
      # @example has_n(x).to(...)
      #
      #   # You can declare which class it has relationship to.
      #   # The generated relationships will be prefixed with the name of that class.
      #   class FolderNode
      #      include Neo4j::ActiveNode
      #      has_n(:files).to(File)
      #      # Same as has_n(:files).to("File")
      #   end
      #
      #   FolderNode.files #=> 'File#files' the name of the relationship
      #
      # @example has_n(x).from(class, has_n_name)
      #
      #   # generate accessor method for traversing and adding relationship on incoming nodes.
      #   class FileNode
      #      include Neo4j::ActiveNode
      #      has_one(:folder).from(FolderNode.files)
      #      # or same as
      #      has_one(:folder).from(FolderNode, :files)
      #   end
      #
      #
      # @return [Neo4j::ActiveNode::HasN::DeclRel] a DSL object where the has_n relationship can be further specified
      def has_n(rel_type)
        clazz = self
        module_eval(%Q{
                def #{rel_type}()
                    dsl = _decl_rels_for('#{rel_type}'.to_sym)
                    Neo4j::ActiveNode::HasN::Nodes.new(self, dsl)
                end}, __FILE__, __LINE__)


        module_eval(%Q{
                def #{rel_type}_rels
                    dsl = _decl_rels_for('#{rel_type}'.to_sym)
                    dsl.all_relationships(self)
                end}, __FILE__, __LINE__)

        instance_eval(%Q{
          def #{rel_type}
            _decl_rels[:#{rel_type}].rel_type
          end}, __FILE__, __LINE__)

        _decl_rels[rel_type.to_sym] = DeclRel.new(rel_type, false, clazz)
      end
    end

  end
end