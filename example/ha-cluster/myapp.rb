require "rubygems"
require "bundler/setup"
require 'fileutils'
require 'neo4j'
require 'neo4j-enterprise'

def start(machine_id)
  #Neo4j::Config.default_file = 'config.yml' # use local config file

  # override this default config with this machine configuration
  Neo4j.config['ha.db'] = true
  Neo4j.config['ha.server_id'] = machine_id
  Neo4j.config['ha.server'] = "localhost:600#{machine_id}"
  Neo4j.config['ha.pull_interval'] = '500ms'
  Neo4j.config['ha.discovery.enabled'] = false
  other_machines = [1,2,3].map{|id| "localhost:500#{id}"}.join(',')
  puts "ha.initial_hosts: #{other_machines}"
  Neo4j.config['ha.initial_hosts'] = other_machines
  Neo4j.config['ha.cluster_server'] = "localhost:500#{machine_id}"

  Neo4j.config[:storage_path] = "db/neo#{machine_id}"
  Neo4j.start
end
