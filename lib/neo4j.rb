include Java

require 'neo4j/neo4j-kernel-1.1.jar'
require 'neo4j/geronimo-jta_1.1_spec-1.1.1.jar'

require 'neo4j/node'
require 'neo4j/transaction'
require 'neo4j/version'

module Neo4j

  DEFAULT_CONFIG = {:storage_path => 'tmp/neo4j'}

  class << self

    def start(new_instance=nil)
      @instance = new_instance if new_instance
      instance
    end

    def instance
      @instance ||= org.neo4j.kernel.EmbeddedGraphDatabase.new(config[:storage_path])
    end

    def config()
      @config ||= DEFAULT_CONFIG.clone
    end

    def shutdown(new_instance = @instance)
      new_instance.shutdown if new_instance
      @instance = nil if new_instance == @instance
    end
  end




end
