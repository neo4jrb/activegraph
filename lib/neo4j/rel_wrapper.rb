class Neo4j::Relationship

  module Wrapper
    def wrapper
      return self unless props.has_key?(:_classname) && !props[:_classname].nil?
      begin
      found_class = props[:_classname].constantize
      rescue NameError
        return self
      end
      wrapped_rel = found_class.new
      wrapped_rel.init_on_load(self, self.start_node, self.end_node, self.rel_type)
      wrapped_rel
    end
  end

end