require 'neo4j-enterprise'
require 'fileutils'
require 'tmpdir'

module Neo4j

  module Rails

    # Configures Neo4j HA and Zookeeper in order to be used from a rails console
    # @see Railtie
    module HaConsole
      class << self
        def machine_id
          (defined? IRB) ? 2 : 1
        end

        def proj_root
          Object::Rails.root
        end

        def storage_path(id = machine_id)
          File.expand_path("db/ha_neo_#{id}", proj_root)
        end

        def config_machine(id = machine_id)
          puts "config_machine #{id}"
          # override this default config with this machine configuration
          Neo4j.config['ha.db'] = true
          Neo4j.config['ha.server_id'] = id
          Neo4j.config['ha.server'] = "localhost:600#{machine_id}"
          Neo4j.config['ha.pull_interval'] = "2"
          Neo4j.config[:storage_path] = storage_path(id)

          copy_config unless File.exist?(config_dir)
          require "#{config_dir}/zookeeper"
        end

        def config_dir
          File.expand_path("neo4j_ha_console/zookeeper", Dir.tmpdir)
        end

        def copy_config
          source_dir = File.expand_path("zookeeper", File.dirname(__FILE__))
          system("mkdir -p #{File.expand_path("..", config_dir)}")
          system("cp -r #{source_dir} #{config_dir}")
        end

        def zookeeper_running?
          Zookeeper.pid_file?
        end

        def start_zookeeper
          Zookeeper.start unless zookeeper_running?
        end

        def shutdown_zookeeper
          if zookeeper_running?
            Zookeeper.shutdown
          else
            puts "Can't shutdown zookeeper - no PID file found for zookeeper process at #{Zookeeper.pid_file}"
          end
        end

      end
    end
  end
end

