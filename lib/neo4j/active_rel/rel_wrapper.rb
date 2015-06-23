class Neo4j::Relationship
  module Wrapper
    def wrapper
      props.symbolize_keys!
      begin
        most_concrete_class = sorted_wrapper_classes
        wrapped_rel = most_concrete_class.constantize.new
      rescue NameError
        return self
      end

      wrapped_rel.init_on_load(self, self._start_node_id, self._end_node_id, self.rel_type)
      wrapped_rel
    end

    private

    def sorted_wrapper_classes
      props[Neo4j::Config.class_name_property] || class_from_type
    end

    def class_from_type
      Neo4j::ActiveRel::Types::WRAPPED_CLASSES[rel_type] || Neo4j::ActiveRel::Types::WRAPPED_CLASSES[rel_type] = rel_type.camelize
    end
  end
end
