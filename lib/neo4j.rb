include Java

require 'forwardable'

require 'neo4j/jars/neo4j-kernel-1.1.jar'
require 'neo4j/jars/geronimo-jta_1.1_spec-1.1.1.jar'
require 'neo4j/jars/lucene-core-2.9.2.jar'
require 'neo4j/jars/neo4j-index-1.1.jar'

require 'neo4j/to_java'
require 'neo4j/version'
require 'neo4j/equal'
require 'neo4j/index'
require 'neo4j/lucene_synchronizer'
require 'neo4j/relationship_traverser'
require 'neo4j/database'
require 'neo4j/node_traverser'
require 'neo4j/property'
require 'neo4j/transaction'
require 'neo4j/node_relationship'
require 'neo4j/relationship'
require 'neo4j/node'
require 'neo4j/mapping/property_class_methods'
require 'neo4j/mapping/index_class_methods'
require 'neo4j/mapping/relationship_class_methods'
require 'neo4j/mapping/decl_relationship_dsl'
require 'neo4j/mapping/has_n'
require 'neo4j/mapping/node_mixin'
require 'neo4j/node_mixin'

module Neo4j

  DEFAULT_CONFIG = {:storage_path => 'tmp/neo4j'}

  class << self

    def start(new_instance=nil)
      @instance = new_instance if new_instance
      instance
    end

    def db
      @db ||= Database.new(config)
    end

    def config()
      @config ||= DEFAULT_CONFIG.clone
    end

    def shutdown(this_db = @db)
      this_db.shutdown if this_db
      @db = nil if this_db == @db
    end
  end


end
