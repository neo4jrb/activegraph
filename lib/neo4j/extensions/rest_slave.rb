require 'rubygems'
require 'net/http'
require 'thread'
require 'json'
#require 'sinatra/base'
require 'neo4j/extensions/rest/stubs'


require 'neo4j/extensions/tx_tracker'

module Neo4j

  module Rest #:nodoc: all
    def self.base_uri
      Neo4j::Config[:master_neo4j_uri]
    end
  end
  

  def self.replicate
    # TODO find uri from /neo instead 
    uri = Neo4j::TxNodeList.instance._uri
    tx_node_list = Neo4j::Rest::NodeStub.new(uri)
    tx_node = tx_node_list.relationships.outgoing(:tx_nodes).nodes.first
    Neo4j::Transaction.run do
      Neo4j::TxNodeList.instance.redo_tx(tx_node)
    end
  end

  Config[:master_neo4j_uri] = 'http://localhost:9123'
end