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
  

  # TODO This is not working yet !
  def self.replicate
    neo_master = Neo4j::Rest::NodeStub.new(Config[:master_neo4j_uri] + "/neo")
    neo_ref_node = Neo4j::Rest::NodeStub.new(neo_master[:ref_node])
    tx_node_list = neo_ref_node.rels.outgoing(:tx_node_list).nodes.first
    tx_node = tx_node_list.rels.outgoing(:tx_nodes).nodes.first
    Neo4j::Transaction.run do
      Neo4j::TxNodeList.instance.redo_tx(tx_node)
    end
  end

  Config[:master_neo4j_uri] = 'http://localhost:9123'
end