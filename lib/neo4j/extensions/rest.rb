# This is a complete example and a spike of how RESTful Neo4j API would work

require 'rubygems'
require 'thread'
require 'json'
require 'sinatra/base'

module Neo4j

  # contains a list of rest node class resources
  REST_NODE_CLASSES = []  

  
  # Add some generic RESTful resources
  #
  #
  Sinatra::Application.get("/test") do
    #      content_type :html
    "<html><body><h2>Neo4j.rb is alive !</h2></body></html>"
  end

  Sinatra::Application.post("/neo") do
    body = request.body.read
    Object.class_eval body
    200
  end


  Sinatra::Application.get("/neo") do
    content_type :json
    {:classes => REST_NODE_CLASSES}.to_json
  end

  Sinatra::Application.get("/relationships/:id") do
    content_type :json
    Neo4j::Transaction.run do
      rel = Neo4j.load_relationship(params[:id].to_i)
      return 404, "Can't find relationship with id #{params[:id]}" if rel.nil?
      {:properties => rel.props}.to_json
    end
  end



  # Creates a number of resources for the class using this mixin.
  #
  # The following resources are created:
  #
  # <b>add new class</b>        <code>POST /neo</code> post ruby code of a neo4j node class
  # <b>node classes</b>         <code>GET /neo</code> - returns hyperlinks to /nodes/classname
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

    #:nodoc:
    URL_REGEXP = Regexp.new '((http[s]?|ftp):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)$'

    def _uri
      "#{self.class._base_uri}#{self.class._uri_rel}/#{neo_node_id}"
    end

    def _uri_rel
      "#{self.class._uri_rel}/#{neo_node_id}"      
    end



    def self.included(c)
      c.property :classname
      c.index :classname # index classname so that we can search on it
      c.extend ClassMethods
      uri_rel = c._uri_rel

      Neo4j::REST_NODE_CLASSES << uri_rel
      
      #puts "Register Neo Node Class #{uri_rel}"

      Sinatra::Application.get("#{uri_rel}/:id/traverse") do
        content_type :json
        Neo4j::Transaction.run do
          node = Neo4j.load(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?

          relationship = params['relationship']
          depth = params['depth']
          depth ||= 1
          uris = node.traverse.outgoing(relationship.to_sym).depth(depth.to_i).collect{|node| node._uri}
          {'uri_list' => uris}.to_json
        end
      end


      Sinatra::Application.get("#{uri_rel}/:id/:prop") do
        content_type :json
        Neo4j::Transaction.run do
          node = Neo4j.load(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          prop = params[:prop].to_sym
          if node.class.relationships_info.keys.include?(prop)      # TODO looks weird, why this complicated
            rels = node.send(prop) || []
            rels.map{|rel| rel.props}.to_json
          else
            {prop => node.get_property(prop)}.to_json
          end
        end
      end


      Sinatra::Application.post("#{uri_rel}/:id/:rel") do
        content_type :json
        new_id = Neo4j::Transaction.run do
          node = Neo4j.load(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          rel = params[:rel]

          body = request.body.read
          data = JSON.parse(body)
          uri = data['uri']
          match = URL_REGEXP.match(uri)
          return 400, "Bad node uri '#{uri}'" if match.nil?
          to_clazz, to_node_id = match[6].split('/')

          other_node = Neo4j.load(to_node_id.to_i)
          return 400, "Unknown other node with id '#{to_node_id}'" if other_node.nil?

          if to_clazz != other_node.class.to_s
            return 400, "Wrong type id '#{to_node_id}' expected '#{to_clazz}' got '#{other_node.class.to_s}'"
          end

          rel_obj = node.relationships.outgoing(rel) << other_node # node.send(rel).new(other_node)

          return 400, "Can't create relationship to #{to_clazz}" if rel_obj.nil?

          rel_obj.neo_relationship_id
        end
        redirect "/relations/#{new_id}", 201 # created
      end


      Sinatra::Application.put("#{uri_rel}/:id/:prop") do
        content_type :json
        Neo4j::Transaction.run do
          node = Neo4j.load(params[:id])
          property = params[:prop]
          body = request.body.read
          data = JSON.parse(body)
          value = data[property]
          return 409, "Can't set property #{property} with JSON data '#{body}'" if value.nil?
          node.set_property(property, value)
          200
        end
      end

      Sinatra::Application.get("#{uri_rel}/:id") do
        content_type :json

        Neo4j::Transaction.run do
          node = Neo4j.load(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          relationships = node.relationships.outgoing.inject({}) {|hash,v| hash[v.relationship_type.to_s] = "#{c._base_uri}/relationships/#{v.neo_relationship_id}"; hash }
          {:relationships => relationships, :properties => node.props}.to_json
        end
      end

      Sinatra::Application.put("#{uri_rel}/:id") do
        content_type :json
        Neo4j::Transaction.run do
          body = request.body.read
          data = JSON.parse(body)
          properties = data['properties']
          node = Neo4j.load(params[:id])
          node.update(properties, true)
          response = node.props.to_json
          response
        end
      end

      Sinatra::Application.delete("#{uri_rel}/:id") do
        content_type :json
        Neo4j::Transaction.run do
          node = Neo4j.load(params[:id])
          return 404, "Can't find node with id #{params[:id]}" if node.nil?
          node.delete
          ""
        end
      end

      Sinatra::Application.post("#{uri_rel}") do
        content_type :json
        new_id = Neo4j::Transaction.run do
          p = c.new
          data = JSON.parse(request.body.read)
          properties = data['properties']
          p.update(properties)
          p.neo_node_id
        end
        redirect "#{uri_rel}/#{new_id.to_s}", 201 # created
      end

      # Allows searching for nodes (provided that they are indexed). Supports the following:
      # <code>/nodes/classname?search=name:hello~</code>:: Lucene query string
      # <code>/nodes/classname?name=hello</code>:: Exact match on property
      # <code>/nodes/classname?sort=name,desc</code>:: Specify sorting order
      Sinatra::Application.get("#{uri_rel}") do
        content_type :json
        Neo4j::Transaction.run do
          resources = c.find(params) # uses overridden find method -- see below
          resources.map{|res| res.props}.to_json
        end
      end
    end


    # Overwrites class methods in NodeMixin when RestMixin is included.
    module ClassMethods

      def _base_uri
        host = Sinatra::Application.host
        port = Sinatra::Application.port
        "http://#{host}:#{port}"
      end

      def _uri_rel
        clazz = root_class.to_s.gsub(/::/, '-')
        "/nodes/#{clazz}"
      end


      # Overrides 'find' so that we can simply pass a query parameters object to it, and
      # search resources accordingly.
      def find(query=nil, &block)
        return super(query, &block) if query.nil? || query.kind_of?(String)

        if query[:limit]
          limit = query[:limit].split(/,/).map{|i| i.to_i}
          limit.unshift(0) if limit.size == 1
        end

        # Build search query
        results =
                if query[:search]
                  super(query[:search])
                else
                  search = {:classname => self.name}
                  query.each_pair do |key, value|
                    search[key.to_sym] = value unless [:sort, :limit].include? key.to_sym
                  end
                  super(search)
                end

        # Add sorting to the mix
        if query[:sort]
          last_field = nil
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
        end

        # Return only the requested subset of results (TODO: can this be done more efficiently within Lucene?)
        if limit
          (limit[0]...(limit[0]+limit[1])).map{|n| results[n] }
        else
          results
        end
      end
    end
  end

  class RestServer
    class << self
      attr_accessor :thread
      
      def on_neo_started(neo_instance)
        start
      end

      def on_neo_stopped(neo_instance)
        stop
      end


      def start
        puts "RESTful already started" if @thread
        return if @thread

        @thread = Thread.new do
          puts "Start Restful server at port #{Config[:rest_port]}"
          Sinatra::Application.run! :port => Config[:rest_port]
        end
      end

      def stop
        if @thread
          # TODO must be a nicer way to do this - to shutdown sinatra
          @thread.kill
          @thread = nil
        end
      end
    end
  end


  #:nodoc:
  def self.load_rest
    Neo4j::Config.defaults[:rest_port] = 9123
    Neo4j.event_handler.add(RestServer)
  end

  load_rest


end
