module Neo4j::Mapping
  module ClassMethods
    # Used to hold information about which relationships and properties has been declared.
    module Root
      def root_class(clazz)
        @@_all_decl_rels  ||= {}
        @@_all_decl_props ||= {}
        @@_all_decl_rels[clazz] ||= {}
        @@_all_decl_props[clazz] ||= {}
        @_decl_rels  = @@_all_decl_rels[clazz]
        @_decl_props = @@_all_decl_props[clazz]
      end


      # a hash of all relationships which has been declared with a has_n or has_one using Neo4j::Mapping::ClassMethods::Relationship
      def _decl_rels
        @@_all_decl_rels[self] ||= {}
        @_decl_rels = @@_all_decl_rels[self]
      end

      # a hash of all properties which has been declared with <tt>property</tt> using the Neo4j::Mapping::ClassMethods::Property
      def _decl_props
        @@_all_decl_props[self] ||= {}
        @_decl_props = @@_all_decl_props[self]
      end

    end
  end
end
