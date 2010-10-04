module Neo4j::Mapping
  module ClassMethods
    module Root
      #attr_reader :_decl_rels, :_decl_props

      def root_class(clazz)
        @@_all_decl_rels  ||= {}
        @@_all_decl_props ||= {}
        @@_all_decl_rels[clazz] ||= {}
        @@_all_decl_props[clazz] ||= {}
        @_decl_rels  = @@_all_decl_rels[clazz]
        @_decl_props = @@_all_decl_props[clazz]
      end


      def _decl_rels
        @@_all_decl_rels[self] ||= {}
        @_decl_props = @@_all_decl_rels[self]
      end

      def _decl_props
        @@_all_decl_props[self] ||= {}
        @_decl_props = @@_all_decl_props[self]
      end

    end
  end
end
