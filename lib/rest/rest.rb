# This is a complete example and a spike of how RESTful Neo4j API would work

require 'rubygems'
require 'json'
require 'sinatra/base'
require 'neo4j'

# This mixin creates the following restful resources
# POST /[classname]/ Response: 201 with Location header to URI of the new resource representing created node
# GET /[classname]/[neo_id] Response: 200 with JSON representation of the node
# GET /[classname]/[neo_id]/[property_name] Response: 200 with JSON representation of the property of the node
# PUT /[classname]/[neo_id]/[property_name] sets the property with the content in the put request
#
# TODO delete and RESTful transaction (which will map to neo4j transactions)
#
module RestMixin

  def self.included(c)
    classname = c.to_s

    Sinatra::Application.get("/#{classname}/:id/:prop") do
      content_type :json
      node = Neo4j.load(params[:id])
      {params[:prop]=>node.get_property(params[:prop])}.to_json
    end

    Sinatra::Application.put("/#{classname}/:id/:prop") do
      content_type :json
      node = Neo4j.load(params[:id])
      property = params[:prop]
      body = request.body.read
      data = JSON.parse(body)
      value = data[property]
      return 409, "Can't set property #{property} with JSON data '#{body}'" if value.nil?
      node.set_property(property, value)
      200
    end

    Sinatra::Application.get("/#{classname}/:id") do
      content_type :json
      node = Neo4j.load(params[:id])
      return 404, "Can't find node with id #{params[:id]}" if node.nil?
      node.props.to_json
    end

    Sinatra::Application.post("/#{classname}") do
      p = c.new
      data = JSON.parse(request.body.read)
      p.update(data)
      redirect "/#{classname}/#{p.neo_node_id.to_s}", 201 # created
    end
  end
end


#
#
#Sinatra::Application.run! :port => 9123
