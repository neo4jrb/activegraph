module Neo4j

# TOOD - maybe we should just make all nodes available as REST resources ???
  module NodeMixin
    def _uri
      "#{Neo4j::Rest.base_uri}#{_uri_rel}"
    end

    def _uri_rel
      clazz = self.class.root_class.to_s #.gsub(/::/, '-') TODO urlencoding
      "/nodes/#{clazz}/#{neo_node_id}"
    end
  end


end