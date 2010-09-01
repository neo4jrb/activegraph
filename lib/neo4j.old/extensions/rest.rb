require 'net/http'
require 'thread'
require 'json'
require 'sinatra/base'

require 'neo4j/extensions/rest/rest'
require 'neo4j/extensions/rest/rest_mixin'
require 'neo4j/extensions/rest/stubs'
require 'neo4j/extensions/rest/server'

# Provides Neo4j::NodeMixin::ClassMethods#all
require 'neo4j/extensions/reindexer'


module Neo4j
  # Make the ReferenceNode available as a REST resource
  # not possible to do much without that node being exposed ...
  class ReferenceNode
    include Neo4j::RestMixin
  end
end
