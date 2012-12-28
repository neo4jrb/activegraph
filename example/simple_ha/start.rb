require "rubygems"
require "bundler/setup"

#GraphDatabaseService db = new HighlyAvailableGraphDatabaseFactory().
#    newHighlyAvailableDatabaseBuilder( path ).
#    setConfig( config ).
#    newGraphDatabase();


require 'neo4j-community'
require 'neo4j-advanced'
require 'neo4j-enterprise'
require 'neo4j-core'


def to_java_map(to_hash)
  map = java.util.HashMap.new
  to_hash.each_pair do |k, v|
    case v
      when TrueClass
        map[k.to_s] = "true"
      when FalseClass
        map[k.to_s] = "false"
      when String, Fixnum, Float
        map[k.to_s] = v.to_s
      else
        puts "OJ #{v}"
      # skip list and hash values - not accepted by the Java Neo4j API
    end
  end
  map
end

# Use Neo4j::Config
def start(machine_id)
  puts "start instance #{machine_id}"

  config = {}
  config['ha.server_id'] = machine_id
  config['ha.discovery.enabled'] = false
  config['ha.cluster_server'] = "localhost:500#{machine_id}"
  config['ha.server'] = "localhost:636#{machine_id}"
  #config['ha.pull_interval'] = '500ms'
  other_machines = [1,2,3].map{|id| "localhost:500#{id}"}.join(',')
  puts "ha.initial_hosts: #{other_machines}"
  config['ha.initial_hosts'] = other_machines


  builder = Java::OrgNeo4jGraphdbFactory::HighlyAvailableGraphDatabaseFactory.new()
  builder = builder.newHighlyAvailableDatabaseBuilder("db/neo#{machine_id}")
  puts "config.to_java_map #{config.inspect}"
  builder = builder.setConfig(to_java_map(config))
  db = builder.newGraphDatabase()
  db.start
  puts "IS MASTER #{db.isMaster}"
end


# Use property file
def start_raw(id)
  puts "start raw instance #{id}"
  builder = Java::OrgNeo4jGraphdbFactory::HighlyAvailableGraphDatabaseFactory.new()
  builder = builder.newHighlyAvailableDatabaseBuilder("db/db#{id}")
  builder = builder.loadPropertiesFromFile("config#{id}.properties")
  db = builder.newGraphDatabase()
  db.start
  puts "IS MASTER #{db.isMaster()}"
end

start(ARGV[0])