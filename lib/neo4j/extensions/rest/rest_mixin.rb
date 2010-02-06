module Neo4j

  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    # See Neo4j::RestMixin#read
    def read
    end
  end

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
  # <b>view relationship</b>::  <code>GET /rels/id</code>
  # <b>list rels</b>:: <code>GET /nodes/classname/id/relationship-type</code>
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
  #   {"rels" : {"type1":"http://0.0.0.0:4567/rels/0","type2":"http://0.0.0.0:4567/rels/1"},
  #    "properties" : {"_neo_id":1,"_classname":"MyNode"}}
  #
  module RestMixin

    def _uri
      "#{Neo4j::Rest.base_uri}#{_uri_rel}"
    end

    def _uri_rel
      clazz = self.class.root_class.to_s #.gsub(/::/, '-') TODO urlencoding
      "/nodes/#{clazz}/#{neo_id}"
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
    def del(options={})
      super()
    end


    def self.included(c)
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

        if query[:search]
          # Use Lucene
          results = super(query[:search])
          results = [*apply_lucene_sort(query[:sort], results)] rescue [*super(query[:search])]

        else
          # Use traverser
          results = apply_ruby_sort(query[:sort], apply_traverser_conditions(query))
        end

        apply_limits(query[:limit], results)
      end

      # :nodoc:
      def symbolize_keys(hash)
        # Borrowed from ActiveSupport
        hash.inject({}) do |options, (key, value)|
          options[(key.to_sym rescue key) || key] = value
          options
        end
      end

      protected

      # Searches for nodes matching conditions by using a traverser.
      def apply_traverser_conditions(query)
        query = query.reject{|key, value| [:sort, :limit, :classname].include? key }

        index_node = Neo4j::IndexNode.instance
        raise 'Index node is nil. Make sure you have called Neo4j.load_reindexer' if index_node.nil?
        traverser = index_node.traverse.outgoing(root_class)

        traverser.filter do |position|
          node = position.current_node
          position.depth == 1 and
            query.inject(true) do |meets_condition, (key, value)|
              meets_condition && (node.send(key) == value)
            end
        end
      end

      # Sorts a list of results according to a string of comma-separated fieldnames (optionally
      # with 'asc' or 'desc' thrown in). For use in cases where we don't go via Lucene.
      def apply_ruby_sort(sort_string, results)
        if sort_string
          sort_fields = sort_string.to_s.split(/,/)
          [*results].sort do |x,y|
            catch(:item_order) do
              sort_fields.each_index do |index|
                field = sort_fields[index]
                unless %w(asc desc).include?(field)
                  item_order = if sort_fields[index + 1] == 'desc'
                    (y.send(field) || '') <=> (x.send(field) || '')
                  else
                    (x.send(field) || '') <=> (y.send(field) || '')
                  end
                  throw :item_order, item_order unless item_order == 0
                end
              end
              0
            end
          end
        else
          [*results]
        end
      end

      # Applies Lucene sort instructions to a Neo4j::SearchResult object.
      def apply_lucene_sort(sort_string, results)
        return results if sort_string.nil?
        last_field = nil

        sort_string.to_s.split(/,/).each do |field|
          if %w(asc desc).include? field
            results = results.sort_by(field == 'asc' ? Lucene::Asc[last_field] : Lucene::Desc[last_field])
            last_field = nil
          else
            results = results.sort_by(Lucene::Asc[last_field]) unless last_field.nil?
            last_field = field
          end
        end
        results.sort_by(Lucene::Asc[last_field]) unless last_field.nil?
        results
      end

      # Return only the requested subset of results for pagination
      # (TODO: can this be done more efficiently within Lucene?)
      def apply_limits(limit_string, results)
        if limit_string
          limit = limit_string.to_s.split(/,/).map{|i| i.to_i}
          limit.unshift(0) if limit.size == 1

          (limit[0]...(limit[0]+limit[1])).map{|n| results[n] }
        else
          results
        end
      end

    end
  end

end