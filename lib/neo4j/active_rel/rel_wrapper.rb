class Neo4j::Relationship

  module Wrapper
    def wrapper
      props.symbolize_keys!
      return self unless props.is_a?(Hash) && props.has_key?(Neo4j::Config.class_name_property)
      begin
      found_class = props[Neo4j::Config.class_name_property].constantize
      rescue NameError
        return self
      end
      wrapped_rel = found_class.new
      wrapped_rel.init_on_load(self, self._start_node_id, self._end_node_id, self.rel_type)
      wrapped_rel
    end
  end

end