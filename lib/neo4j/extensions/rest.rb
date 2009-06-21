# This is a complete example and a spike of how RESTful Neo4j API would work

require 'rubygems'
require 'thread'
require 'json'
require 'sinatra/base'

# This mixin creates the following restful resources
# POST /nodes/[classname]/ Response: 201 with Location header to URI of the new resource representing created node
# GET /nodes/[classname]/[neo_id] Response: 200 with JSON representation of the node
# GET /nodes/[classname]/[neo_id]/[property_name] Response: 200 with JSON representation of the property of the node
# PUT /nodes/[classname]/[neo_id]/[property_name] sets the property with the content in the put request
#
# TODO delete and RESTful transaction (which will map to neo4j transactions)
#
module RestMixin

  #URL_REGEXP = Regexp.new '((http[s]?|ftp):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)(.*)?(#[\w\-]+)?$'
  URL_REGEXP = Regexp.new '((http[s]?|ftp):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)$'



  Sinatra::Application.get("/test") do
    #      content_type :html
    "<html><body><h2>Neo4j.rb is alive !</h2></body></html>"
  end

  Sinatra::Application.post("/neo") do
    body = request.body.read
    Object.class_eval body
    200
  end

  Sinatra::Application.get("/relations/:id") do
    content_type :json
    Neo4j::Transaction.run do
      rel = Neo4j.load_relationship(params[:id].to_i)
      error 404, "Can't find relationship with id #{params[:id]}" if rel.nil?
      rel.props.to_json
    end
  end


  def _uri
    "#{_base_uri}/nodes/#{self.class.to_s}/#{self.neo_node_id}"
  end

  def _base_uri
    host = Sinatra::Application.host
    port = Sinatra::Application.port
    "http://#{host}:#{port}"
  end


  def self.included(c)
    c.property :classname
    c.index :classname # index classname so that we can search on it
    c.extend ClassMethods
    classname = c.to_s

    #puts "Register Neo Node Class /nodes/#{classname}"


    Sinatra::Application.get("/nodes/#{classname}/:id/traverse") do
      content_type :json
      Neo4j::Transaction.run do
        node = Neo4j.load(params[:id])
        error 404, "Can't find node with id #{params[:id]}" if node.nil?

        relation = params['relation']
        depth = params['depth']
        depth ||= 1
        uris = node.traverse.outgoing(relation.to_sym).depth(depth.to_i).collect{|node| node._uri}
        {'uri_list' => uris}.to_json
      end
    end


    Sinatra::Application.get("/nodes/#{classname}/:id/:prop") do
      content_type :json
      Neo4j::Transaction.run do
        node = Neo4j.load(params[:id])
        error 404, "Can't find node with id #{params[:id]}" if node.nil?
        prop = params[:prop].to_sym
        if node.class.relationships_info.keys.include?(prop)
          rels = node.send(prop) || []
          rels.map{|rel| rel.props}.to_json
        else
          {prop => node.get_property(prop)}.to_json
        end
      end
    end


    Sinatra::Application.post("/nodes/#{classname}/:id/:rel") do
      content_type :json
      new_id = Neo4j::Transaction.run do
        node = Neo4j.load(params[:id])
        error 404, "Can't find node with id #{params[:id]}" if node.nil?
        rel = params[:rel]

        # does this relationship exist ?
        if !node.class.relationships_info.keys.include?(rel.to_sym)
          error 409, "Can't add relation on '#{rel}' since it does not exist"
        end
        body = request.body.read
        data = JSON.parse(body)
        uri = data['uri']
        match = URL_REGEXP.match(uri)
        error 400, "Bad node uri '#{uri}'" if match.nil?
        to_clazz, to_node_id = match[6].split('/')

        other_node = Neo4j.load(to_node_id.to_i)
        error 400, "Unknown other node with id '#{to_node_id}'" if other_node.nil?

        if to_clazz != other_node.class.to_s
          error 400, "Wrong type id '#{to_node_id}' expected '#{to_clazz}' got '#{other_node.class.to_s}'"
        end

        rel_obj = node.send(rel).new(other_node)

        error 400, "Can't create relationship to #{to_clazz}" if rel_obj.nil?

        rel_obj.neo_relationship_id
      end
      redirect "/relations/#{new_id}", 201 # created
    end


    Sinatra::Application.put("/nodes/#{classname}/:id/:prop") do
      content_type :json
      Neo4j::Transaction.run do
        node = Neo4j.load(params[:id])
        property = params[:prop]
        body = request.body.read
        data = JSON.parse(body)
        value = data[property]
        error 409, "Can't set property #{property} with JSON data '#{body}'" if value.nil?
        node.set_property(property, value)
        200
      end
    end

    Sinatra::Application.get("/nodes/#{classname}/:id") do
      content_type :json
      Neo4j::Transaction.run do
        node = Neo4j.load(params[:id])
        error 404, "Can't find node with id #{params[:id]}" if node.nil?
        node.props.to_json
      end
    end

    Sinatra::Application.put("/nodes/#{classname}/:id") do
      content_type :json
      Neo4j::Transaction.run do
        body = request.body.read
        data = JSON.parse(body)
        node = Neo4j.load(params[:id])
        node.update(data, true)
        response = node.props.to_json
        response
      end
    end

    Sinatra::Application.delete("/nodes/#{classname}/:id") do
      content_type :json
      Neo4j::Transaction.run do
        node = Neo4j.load(params[:id])
        error 404, "Can't find node with id #{params[:id]}" if node.nil?
        node.delete
        ""
      end
    end

    Sinatra::Application.post("/nodes/#{classname}") do
      content_type :json
      new_id = Neo4j::Transaction.run do
        p = c.new
        data = JSON.parse(request.body.read)
        #puts "POST DATA #{data.inspect} TO #{p}"
        p.update(data)
        #puts "POSTED #{p}"
        p.neo_node_id
      end
      redirect "/nodes/#{classname}/#{new_id.to_s}", 201 # created
    end

    # Allows searching for nodes (provided that they are indexed). Supports the following:
    # <code>/nodes/classname?search=name:hello~</code>:: Lucene query string
    # <code>/nodes/classname?name=hello</code>:: Exact match on property
    # <code>/nodes/classname?sort=name,desc</code>:: Specify sorting order
    Sinatra::Application.get("/nodes/#{classname}") do
      content_type :json
      Neo4j::Transaction.run do
        resources = c.find(params) # uses overridden find method -- see below
        resources.map{|res| res.props}.to_json
      end
    end
  end


  # Overwrites class methods in NodeMixin when RestMixin is included.
  module ClassMethods
    # Overrides 'find' so that we can simply pass a query parameters object to it, and
    # search resources accordingly.
    def find(query=nil, &block)
      return super(query, &block) if query.nil? || query.kind_of?(String)

      if query[:limit]
        limit = query[:limit].split(/,/).map{|i| i.to_i}
        limit.unshift(0) if limit.size == 1
      end

      # Build search query
      results = if query[:search]
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


  class RestServer
    class << self
      def on_neo_started(neo_instance)
        start
      end

      def on_neo_stopped(neo_instance)
        stop
      end


      def start
        puts "start rest server"
        puts "RESTful already started" if @sinatra
        return if @sinatra

        @sinatra = Thread.new do
          puts "HELLO"
          puts "Start Restful server at port #{Config[:rest_port]}"
          Sinatra::Application.run! :port => Config[:rest_port]
          puts "Restful server started"
#        end
#        @sinatra.join
        end
      end

      def stop
        if @sinatra
          # TODO must be a nicer way to do this - to shutdown sinatra
          @sinatra.kill
          @sinatra = nil
        end
      end
    end
  end

  def self.load_rest
    Neo4j::Config.defaults[:rest_port] = 9123
    Neo4j.event_handler.add(RestServer)
  end

  load_rest

end




