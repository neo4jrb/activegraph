module Neo4j

  module Rails

    module HaConsole

      # Include this in your config/application.rb in order to run a rails console
      # It avoids the Neo4j limitation of only having one process accessing the database by using HA clustering/neo4j-enterprise
      class Railtie < Object::Rails::Railtie

        console do
          Neo4j.config.use do |conf|
            server_id = 2
            conf['ha.server_id'] = server_id
            conf['ha.server'] = "localhost:600#{server_id}"
            conf['ha.cluster_server'] = "localhost:500#{server_id}"
            conf['storage_path'] = File.expand_path("db/ha_neo_#{server_id}", Object::Rails.root)
            puts "Re-Config HA cluster, ha.server_id: #{conf['ha.server_id']}, db: #{conf['storage_path']}"
          end
        end

        config.before_configuration do
          server_id = 1
          config.neo4j['enable_ha'] = true
          config.neo4j['ha.server_id'] = server_id
          config.neo4j['ha.server'] = "localhost:600#{server_id}"
          config.neo4j['ha.pull_interval'] = '500ms'
          config.neo4j['ha.discovery.enabled'] = false
          config.neo4j['ha.initial_hosts'] = [1,2,3].map{|id| "localhost:500#{id}"}.join(',')
          config.neo4j['ha.cluster_server'] = "localhost:500#{server_id}"
          config.neo4j.storage_path = File.expand_path("db/ha_neo_#{server_id}", Object::Rails.root)
          puts "Config HA cluster, ha.server_id: #{config.neo4j['ha.server_id']}, db: #{config.neo4j.storage_path}"
        end
      end
    end
  end
end
