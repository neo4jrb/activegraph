require "rubygems"
require "bundler/setup"
require 'fileutils'
require 'neo4j'


def start(machine_id)
  Neo4j::Config.default_file = 'config.yml' # use local config file

  # override this default config with this machine configuration
  Neo4j.config['ha.machine_id'] = machine_id
  Neo4j.config['ha.server'] = "localhost:600#{machine_id}"
  Neo4j.config['enable_remote_shell'] = "port=933#{machine_id}"
  Neo4j.config[:storage_path] = "db/neo#{machine_id}"
  Neo4j.start
end