module Neo4j

# Creates a number of resources for the class using this mixin.
#
# The following resources are created:
#
# <b>add new class</b>::      <code>POST /neo</code> post ruby code of a neo4j node class
# <b>node classes</b>::       <code>GET /neo</code> - returns hyperlinks to /nodes/classname
# <b>search nodes</b>::       <code>GET /nodes/classname?name=p</code>
# <b>view all nodes</b>::     <code>GET /nodes/classname</code>
# <b>update property</b>::    <code>PUT nodes/classname/id/property_name</code>
# <b>view property</b>::      <code>GET nodes/classname/id/property_name</code>
# <b>delete node</b>::        <code>DELETE nodes/classname/node_id</code>
# <b>update properties</b>::  <code>PUT nodes/classname/node_id</code>
# <b>view node</b>::          <code>GET /nodes/classname/id</code>
# <b>create node</b>::        <code>POST /nodes/classname</code>
# <b>view relationship</b>::  <code>GET /relationships/id</code>
# <b>list relationships</b>:: <code>GET /nodes/classname/id/relationship-type</code>
# <b>add relationship</b>::   <code>POST /nodes/classname/id/relationship-type</code>
# <b>traversal</b>::          <code>GET nodes/classname/id/traverse?relationship=relationship-type&depth=depth</code>
#
# Also provides lucene queries
# <b>Lucene query string</b>::      <code>/nodes/classname?search=name:hello~</code>
# <b>Exact match on property</b>::  <code>/nodes/classname?name=hello</code>
# <b>Specify sorting order</b>::    <code>/nodes/classname?sort=name,desc</code>
# <b>Pagination (offset,num)</b>::  <code>/nodes/classname?limit=100,20</code>#
# 
# When create a new node  by posting to <code>/nodes/classname</code> a 201 will be return with the 'Location' header set to the
# URI of the newly created node.
#
# The JSON representation of a node looks like this
#
#   {"relationships" : {"type1":"http://0.0.0.0:4567/relationships/0","type2":"http://0.0.0.0:4567/relationships/1"},
#    "properties" : {"id":1,"classname":"MyNode"}}
#
  module RestMixin

    def _uri
      "#{Neo4j::Rest.base_uri}#{_uri_rel}"
    end

    def _uri_rel
      clazz = self.class.root_class.to_s #.gsub(/::/, '-') TODO urlencoding
      "/nodes/#{clazz}/#{neo_node_id}"
    end
    
    def initialize(*args)
      super
      # Explicitly index the classname of a node (required for <code>GET /nodes/MyClass</code>
      # Lucene search to work).
      self.class.indexer.on_property_changed(self, 'classname')   # TODO reuse the event_handler instead !
      # This caused the replication_spec.rb to fail
     # Neo4j.event_handler.property_changed(self, 'classname', '', self.class.to_s)
    end

    # Called by the REST API if this node is accessed directly by ID. Any query parameters
    # in the request are passed in a hash. For example if <code>GET /nodes/MyClass/1?foo=bar</code>
    # is requested, <code>MyClass#accessed</code> is called with <code>{'foo' => 'bar'}</code>.
    # By default this method does nothing, but model classes may override it to achieve specific
    # behaviour.
    def read(options={})
    end

    # Called by the REST API if this node is deleted. Any query parameters in the request are passed
    # in a hash.
    def delete(options={})
      super()
    end


    def self.included(c)
      c.property :classname
      c.index :classname # index classname so that we can search on it
      c.extend ClassMethods
      uri_rel = c._uri_rel
      # just for debugging and logging purpose so we know which classes uses this mixin, TODO - probablly not needed
      Neo4j::Rest::REST_NODE_CLASSES[uri_rel] = c
    end


    module ClassMethods

      # todo remove
      def _uri_rel  # :nodoc:
        clazz = root_class.to_s #.gsub(/::/, '-') TODO urlencoding
        "/nodes/#{clazz}"
      end


      # Overrides 'find' so that we can simply pass a query parameters object to it, and
      # search resources accordingly.
      def find(query=nil, &block)
        return super(query, &block) if query.nil? || query.kind_of?(String)

        query = symbolize_keys(query)

        if query[:limit]
          limit = query[:limit].to_s.split(/,/).map{|i| i.to_i}
          limit.unshift(0) if limit.size == 1
        end

        # Build search query
        search = query[:search]
        if search.nil?
          search = {:classname => self.name}
          query.each_pair do |key, value|
            search[key.to_sym] = value unless [:sort, :limit].include? key.to_sym
          end
        end

        # Add sorting to the mix
        if query[:sort]
          last_field = nil
          results = super(search)
          query[:sort].split(/,/).each do |field|
            if %w(asc desc).include? field
              results = results.sort_by(field == 'asc' ? Lucene::Asc[last_field] : Lucene::Desc[last_field])
              last_field = nil
            else
              results = results.sort_by(Lucene::Asc[last_field]) unless last_field.nil?
              last_field = field
            end
          end
          results = results.sort_by(Lucene::Asc[last_field]) unless last_field.nil?
          begin
            results = results.to_a
          rescue NativeException => e
            results = super(search).to_a
          end
        else
          results = super(search).to_a
        end

        # Return only the requested subset of results (TODO: can this be done more efficiently within Lucene?)
        if limit
          (limit[0]...(limit[0]+limit[1])).map{|n| results[n] }
        else
          results
        end
      end

      # :nodoc:
      def symbolize_keys(hash)
        # Borrowed from ActiveSupport
        hash.inject({}) do |options, (key, value)|
          options[(key.to_sym rescue key) || key] = value
          options
        end
      end
    end
  end

end