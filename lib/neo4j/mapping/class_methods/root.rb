require 'active_support/core_ext/class/subclasses'

module Neo4j::Mapping
  module ClassMethods
    # Used to hold information about which relationships and properties has been declared.
    module Root
      def root_class(clazz)
        @@_all_decl_rels  ||= {}
        @@_all_decl_props ||= {}
        @@_all_decl_rels[clazz] ||= {}
        @@_all_decl_props[self] = _decl_props
        @_decl_rels  = @@_all_decl_rels[clazz]
      end


      # a hash of all relationships which has been declared with a has_n or has_one using Neo4j::Mapping::ClassMethods::Relationship
      def _decl_rels
        @@_all_decl_rels[self] ||= {}
        @_decl_props = @@_all_decl_rels[self] # TODO This must be wrong, why does it work ???
      end

    end
  end
end
