module Neo4j

  module Rest #:nodoc: all
    # contains a list of rest node class resources
    REST_NODE_CLASSES = {}

    class RestException < StandardError
      def code; 500; end
    end

    class NotAllowed < RestException
      def code; 403; end
    end

    class Conflict < RestException
      def code; 409; end
    end

    def self.base_uri
      host = Sinatra::Application.host
      port = Sinatra::Application.port
      "http://#{host}:#{port}"
    end

    def self.load_class(clazz)
      clazz = clazz.split("::").inject(Kernel) do |container, name|
        container.const_get(name.to_s)
      end
    rescue NameError
      raise Sinatra::NotFound
    end


    # Extracts query parameters from a URL; e.g. if <code>/resource?foo=bar</code> was requested,
    # <code>{'foo' => 'bar'}</code> is returned.
    def self.query_from_params(params)
      query = nil
      unless (params.nil?)
        query = params.clone
        query.delete('neo_id')
        query.delete('class')
        query.delete('prop')
        query.delete('rel')
      end
      query
    end
    
    # -------------------------------------------------------------------------
    # /neo
    # -------------------------------------------------------------------------

    Sinatra::Application.post("/neo") do
      body = request.body.read
      Object.class_eval body
      200
    end


    Sinatra::Application.get("/neo") do
      if request.accept.include?("text/html")
        html = "<html><body><h2>Neo4j.rb v #{Neo4j::VERSION} is alive !</h2><p/><h3>Defined REST classes</h3>"
        REST_NODE_CLASSES.keys.each {|clazz| html << "Class '" + clazz + "' <br/>"}
        html << "</body></html>"
        html
      else
        content_type :json
        # make it look like it was a node - todo maybe it should be a real Neo4j::Node ...
        properties = {:classes => REST_NODE_CLASSES.keys, :ref_node => Neo4j.ref_node._uri}
        {:properties => properties}.to_json
      end
    end


    # -------------------------------------------------------------------------
    # /rels/<id>
    # -------------------------------------------------------------------------

    Sinatra::Application.get("/rels/:id") do
      content_type :json
      begin
        Neo4j::Transaction.run do
          rel = Neo4j.load_rel(params[:id].to_i)
          return 404, "Can't find relationship with id #{params[:id]}" if rel.nil?
          # include hyperlink to end_node if that has an _uri method
          end_node_hash = {:uri => rel.end_node._uri}

          # include hyperlink to start_node if that has an _uri method
          start_node_hash = {:uri => rel.start_node._uri}

          {:properties => rel.props, :start_node => start_node_hash, :end_node => end_node_hash}.to_json
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end


    # -------------------------------------------------------------------------
    # /nodes/<classname>
    # -------------------------------------------------------------------------

    # Allows searching for nodes (provided that they are indexed). Supports the following:
    # <code>/nodes/classname?search=name:hello~</code>:: Lucene query string
    # <code>/nodes/classname?name=hello</code>:: Exact match on property
    # <code>/nodes/classname?sort=name,desc</code>:: Specify sorting order
    # <code>/nodes/classname?limit=100,20</code>:: Specify offset and number of nodes (for pagination)
    Sinatra::Application.get("/nodes/:class") do
      content_type :json
      clazz = Neo4j::Rest.load_class(params[:class])
      return 404, "Can't find class '#{classname}'" if clazz.nil?

      begin
        Neo4j::Transaction.run do
          resources = clazz.find(Neo4j::Rest.query_from_params(params)) # uses overridden find method -- see below
          resources.map{|res| res.props}.to_json
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end

    Sinatra::Application.post("/nodes/:class") do
      content_type :json

      clazz = Neo4j::Rest.load_class(params[:class])
      return 404, "Can't find class '#{classname}'" if clazz.nil?

      begin
        uri = Neo4j::Transaction.run do
          node = clazz.new
          data = JSON.parse(request.body.read)
          properties = data['properties']
          node.update(properties, Neo4j::Rest.query_from_params(params))
          node._uri
        end
        redirect "#{uri}", 201 # created
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end


    # -------------------------------------------------------------------------
    # /nodes/<classname>/<id>
    # -------------------------------------------------------------------------

    Sinatra::Application.get("/nodes/:class/:id") do
      content_type :json

      begin
        Neo4j::Transaction.run do
          node = Neo4j.load_node(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          node.read(Neo4j::Rest.query_from_params(params))
          relationships = node.rels.outgoing.inject({}) do |hash, v|
            type = v.relationship_type.to_s
            hash[type] ||= []
            hash[type] << "#{Neo4j::Rest.base_uri}/rels/#{v.neo_id}"
            hash
          end
          {:rels => relationships, :properties => node.props}.to_json
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end

    Sinatra::Application.put("/nodes/:class/:id") do
      content_type :json
      begin
        Neo4j::Transaction.run do
          body = request.body.read
          data = JSON.parse(body)
          properties = data['properties'] || {}
          node = Neo4j.load_node(params[:id])
          node.update(properties, Neo4j::Rest.query_from_params(params).merge({:strict => true}))
          node.props.to_json
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end

    Sinatra::Application.delete("/nodes/:class/:id") do
      content_type :json
      begin
        Neo4j::Transaction.run do
          node = Neo4j.load_node(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          node.del(Neo4j::Rest.query_from_params(params))
          ""
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end


    # -------------------------------------------------------------------------
    # /nodes/<classname>/<id>/<property>
    # -------------------------------------------------------------------------

    Sinatra::Application.get("/nodes/:class/:id/traverse") do
      content_type :json
      begin
        Neo4j::Transaction.run do
          node = Neo4j.load_node(params[:id])
          return 404, {'error' => "Can't find node with id #{params[:id]}"}.to_json if node.nil?

          relationship = params['relationship']
          depth = case params['depth']
            when nil then 1
            when 'all' then :all
            else params['depth'].to_i
          end
          return 400, {'error' => "invalid depth parameter - must be an integer"}.to_json  if depth == 0
          
          uris = node.traverse.outgoing(relationship.to_sym).depth(depth).collect{|node| node._uri}
          {'uri_list' => uris}.to_json
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end


    Sinatra::Application.get("/nodes/:class/:id/:prop") do
      content_type :json
      begin
        Neo4j::Transaction.run do
          node = Neo4j.load_node(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          prop = params[:prop].to_sym
          if node.class.relationships_info.keys.include?(prop)      # TODO looks weird, why this complicated
            rels = node.send(prop) || []
            (rels.respond_to?(:props) ? rels.props : rels.map{|rel| rel.props}).to_json
          else
            {prop => node[prop]}.to_json
          end
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end


    Sinatra::Application.put("/nodes/:class/:id/:prop") do
      content_type :json
      begin
        Neo4j::Transaction.run do
          node = Neo4j.load_node(params[:id])
          property = params[:prop]
          body = request.body.read
          data = JSON.parse(body)
          value = data[property]
          return 409, "Can't set property #{property} with JSON data '#{body}'" if value.nil?
          node[property] =  value
          200
        end
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end

    URL_REGEXP = Regexp.new '((http[s]?|ftp):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+\/[\w\-\.]+)$' #:nodoc:

    Sinatra::Application.post("/nodes/:class/:id/:rel") do
      content_type :json
      begin
        new_id = Neo4j::Transaction.run do
          node = Neo4j.load_node(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          rel = params[:rel]

          body = request.body.read
          data = JSON.parse(body)
          uri = data['uri']
          match = URL_REGEXP.match(uri)
          return 400, "Bad node uri '#{uri}'" if match.nil?
          to_clazz, to_node_id = match[6].split('/')

          other_node = Neo4j.load_node(to_node_id.to_i)
          return 400, "Unknown other node with id '#{to_node_id}'" if other_node.nil?

          if to_clazz != other_node.class.to_s
            return 400, "Wrong type id '#{to_node_id}' expected '#{to_clazz}' got '#{other_node.class.to_s}'"
          end

          rel_obj = node.add_rel(rel, other_node)

          return 400, "Can't create relationship to #{to_clazz}" if rel_obj.nil?

          rel_obj.neo_id
        end
        redirect "/rels/#{new_id}", 201 # created
      rescue RestException => exception
        return exception.code, {'error' => $!}.to_json
      rescue Exception => e
        return 500, {'error' => $!, 'backtrace' => e.backtrace}.to_json
      end
    end
  end

end
