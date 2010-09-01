include Java

require 'neo4j/neo4j-kernel-1.1.jar'
require 'neo4j/geronimo-jta_1.1_spec-1.1.1.jar'

require 'neo4j/node'

module Neo4j

  DEFAULT_CONFIG = {:storage_path => 'tmp/neo4j'}

  class << self
    def instance
      @instance ||= org.neo4j.kernel.EmbeddedGraphDatabase.new(config[:storage_path])
    end

    def config
      @config ||= DEFAULT_CONFIG.clone
    end
  end


  class Transaction
    def self.new(instance = Neo4j.instance)
      instance.begin_tx
    end

  end


end
