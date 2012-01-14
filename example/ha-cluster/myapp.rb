require "rubygems"
require "bundler/setup"
require 'fileutils'
require 'neo4j'
require 'neo4j-enterprise'

def start(machine_id)
  Neo4j::Config.default_file = 'config.yml' # use local config file

  # override this default config with this machine configuration
  Neo4j.config['ha.server_id'] = machine_id
  Neo4j.config['ha.server'] = "localhost:600#{machine_id}"
  Neo4j.config['enable_remote_shell'] = "port=933#{machine_id}"

  # since we are all running on localhost we can only enable one online back up server
  # since they all use the port 6362
  Neo4j.config[:online_backup_enabled] = true if machine_id == 1

  Neo4j.config[:storage_path] = "db/neo#{machine_id}"
  Neo4j.start
end
