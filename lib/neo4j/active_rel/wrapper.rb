module Neo4j
  class Relationship

    module Wrapper

      # this is a plugin in the neo4j-core so that the Ruby wrapper will be wrapped around the Neo4j::Node objects
      def wrapper
        if wrapper = _class_wrapper
          wrapped_rel = Neo4j::ActiveRel::RelType._wrapped_rel_types[wrapper].new
          wrapped_rel.init_on_load(self, self.props)
          wrapped_rel
        else
          self
        end
      end

      def _class_wrapper
        if Neo4j::ActiveRel::RelType._wrapped_rel_types[rel_type].class == Class
          rel_type
        end
      end
    end
  end
end

