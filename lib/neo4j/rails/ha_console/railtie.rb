require File.expand_path('../ha_console', __FILE__)

module Neo4j

  module Rails

    module HaConsole

      # Include this in your config/application.rb in order to run a rails console
      # It avoids the Neo4j limitation of only having one process accessing the database by using HA clustering/neo4j-enterprise
      class Railtie < Object::Rails::Railtie
        config.before_configuration do
          Neo4j::Rails::HaConsole.config_machine
          Neo4j::Rails::HaConsole.start_zookeeper
          config.neo4j.storage_path = Neo4j::Rails::HaConsole.storage_path
          puts "HA: #{Neo4j.config['ha.db']}, server_id: #{Neo4j.config['ha.server_id']}, master: #{Neo4j.ha_master?}, storage_path=#{config.neo4j.storage_path}"
        end
      end
    end
  end
end
