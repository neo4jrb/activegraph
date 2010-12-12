include Java

require 'enumerator'
require 'forwardable'
require 'time'
require 'date'

require 'neo4j/jars/neo4j-index-1.2-1.2.M04.jar'
require 'neo4j/jars/neo4j-kernel-1.2-1.2.M04.jar'
require 'neo4j/jars/neo4j-lucene-index-0.2-1.2.M04.jar'
require 'neo4j/jars/geronimo-jta_1.1_spec-1.1.1.jar'
require 'neo4j/jars/lucene-core-3.0.2.jar'

require 'will_paginate/collection'
require 'will_paginate/finders/base'
require 'neo4j/to_java'
require 'neo4j/version'
require 'neo4j/equal'

require 'neo4j/event_handler'
require 'neo4j/type_converters'
require 'neo4j/config'
require 'neo4j/database'
require 'neo4j/neo4j'

require "neo4j/functions/function"
require "neo4j/functions/count"
require "neo4j/functions/sum"


require 'neo4j/index/index'
require 'neo4j/index/class_methods'
require 'neo4j/index/indexer_registry'
require 'neo4j/index/indexer'
require 'neo4j/index/lucene_query'
require 'neo4j/relationship_traverser'
require 'neo4j/node_traverser'
require 'neo4j/property'
require 'neo4j/transaction'
require 'neo4j/node_relationship'
require 'neo4j/load'
require 'neo4j/relationship'
require 'neo4j/node'
require 'neo4j/mapping/class_methods/init_node'
require 'neo4j/mapping/class_methods/init_rel'
require 'neo4j/mapping/class_methods/property'
require 'neo4j/mapping/class_methods/relationship'
require 'neo4j/mapping/class_methods/list'
require 'neo4j/mapping/decl_relationship_dsl'
require 'neo4j/mapping/has_n'
require 'neo4j/mapping/has_list'
require 'neo4j/mapping/node_mixin'
require 'neo4j/mapping/relationship_mixin'
require 'neo4j/mapping/rule'
require 'neo4j/mapping/rule_node'
require 'neo4j/node_mixin'
require 'neo4j/relationship_mixin'
require 'neo4j/mapping/class_methods/rule'

# rails
require 'rails/railtie'
require 'active_model'
require 'neo4j/rails/tx_methods'
require 'neo4j/rails/transaction'
require 'neo4j/rails/railtie'
require 'neo4j/rails/validations/uniqueness'
require 'neo4j/rails/validations/non_nil'
require 'neo4j/rails/finders'
require 'neo4j/rails/mapping/property'
require 'neo4j/rails/validations'
require 'neo4j/rails/callbacks'
require 'neo4j/rails/timestamps'
require 'neo4j/rails/serialization'
require 'neo4j/rails/attributes'
require 'neo4j/rails/persistence'
require 'neo4j/rails/relationships/mapper'
require 'neo4j/rails/relationships/relationship'
require 'neo4j/rails/relationships/relationships'
require 'neo4j/rails/model'
require 'neo4j/rails/lucene_connection_closer'

require 'neo4j/model'
require 'orm_adapter/adapters/neo4j'

# hmm, looks like Enumerator have been moved in some ruby versions
Enumerator = Enumerable::Enumerator unless defined? Enumerator

