require 'enumerator'
require 'forwardable'
require 'time'
require 'date'
require 'tmpdir'

# Rails
require 'rails/railtie'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_model'

require 'will_paginate/collection'
require 'will_paginate/finders/base'

# core extensions
require 'neo4j/core_ext/class/inheritable_attributes'

# Jars

require 'neo4j/jars/core/geronimo-jta_1.1_spec-1.1.1.jar'
require 'neo4j/jars/core/lucene-core-3.1.0.jar'
require 'neo4j/jars/core/neo4j-lucene-index-1.4.1.jar'
require 'neo4j/jars/core/neo4j-kernel-1.4.1.jar'
require 'neo4j/jars/ha/neo4j-management-1.4.1.jar'
require 'neo4j/jars/ha/neo4j-jmx-1.4.1.jar'

module Neo4j

  def self.load_local_jars
    # This is a temporary fix since the HA does not yet work with this JAR
    # It will be solved in a future version of the Java Neo4j library.
    if Neo4j.config[:online_backup_enabled]
      Neo4j.load_online_backup
    else
      # backup and HA does not work with this JAR FILE
      require 'neo4j/jars/core/neo4j-index-1.3-1.3.M01.jar'
    end
  end

  def self.load_shell_jars
    require 'neo4j/jars/ha/neo4j-shell-1.4.1.jar'
  end

  def self.load_online_backup
    require 'neo4j/jars/ha/neo4j-com-1.4.1.jar'
    require 'neo4j/jars/core/neo4j-backup-1.4.1.jar'
    require 'neo4j/jars/ha/netty-3.2.1.Final.jar'
    Neo4j.send(:const_set, :OnlineBackup, org.neo4j.backup.OnlineBackup)
  end

  def self.load_ha_jars
    require 'neo4j/jars/core/neo4j-backup-1.4.1.jar'
    require 'neo4j/jars/ha/log4j-1.2.16.jar'
    require 'neo4j/jars/ha/neo4j-ha-1.4.1.jar'
    require 'neo4j/jars/ha/neo4j-com-1.4.1.jar'
    require 'neo4j/jars/ha/netty-3.2.1.Final.jar'
    require 'neo4j/jars/ha/org.apache.servicemix.bundles.jline-0.9.94_1.jar'
    # require 'neo4j/jars/ha/org.apache.servicemix.bundles.lucene-3.0.1_2.jar' # TODO IS THIS NEEDED ?
    require 'neo4j/jars/ha/zookeeper-3.3.2.jar'
  end
end

module Neo4j
  include Java

  # Enumerator has been moved to top level in Ruby 1.9.2, make it compatible with Ruby 1.8.7
  Enumerator = Enumerable::Enumerator unless defined? Enumerator
end

require 'neo4j/version'
require 'neo4j/neo4j'
require 'neo4j/node'
require 'neo4j/relationship'
require 'neo4j/relationship_set'

require 'neo4j/type_converters/type_converters'

require 'neo4j/index/index'

require 'neo4j/traversal/traversal'

require 'neo4j/property/property'

require 'neo4j/has_n/has_n'

require 'neo4j/node_mixin/node_mixin'

require 'neo4j/relationship_mixin/relationship_mixin'

require 'neo4j/rule/rule'

require 'neo4j/rels/rels'

require 'neo4j/rails/rails'

require 'neo4j/model'

require 'neo4j/migrations/migrations'

require 'neo4j/algo/algo'

require 'neo4j/batch/batch'

require 'orm_adapter/adapters/neo4j'

require 'neo4j/identity_map'