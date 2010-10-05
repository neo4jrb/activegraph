include Java

require 'enumerator'
require 'forwardable'
require 'time'
require 'date'

require 'neo4j/jars/neo4j-kernel-1.1.1.jar'
require 'neo4j/jars/geronimo-jta_1.1_spec-1.1.1.jar'
require 'neo4j/jars/lucene-core-3.0.1.jar'
require 'neo4j/jars/neo4j-lucene-index-0.1-20101002.153213-102.jar'
require 'neo4j/to_java'
require 'neo4j/version'
require 'neo4j/equal'
require 'neo4j/index'
require 'neo4j/relationship_traverser'
require 'neo4j/event_handler'
require 'neo4j/database'
require 'neo4j/node_traverser'
require 'neo4j/property'
require 'neo4j/transaction'
require 'neo4j/node_relationship'
require 'neo4j/load'
require 'neo4j/relationship'
require 'neo4j/node'
require 'neo4j/config'
require 'neo4j/neo4j'
require 'neo4j/mapping/class_methods/init_node'
require 'neo4j/mapping/class_methods/init_rel'
require 'neo4j/mapping/class_methods/root'
require 'neo4j/mapping/class_methods/property'
require 'neo4j/mapping/class_methods/index'
require 'neo4j/mapping/class_methods/relationship'
require 'neo4j/mapping/decl_relationship_dsl'
require 'neo4j/mapping/has_n'
require 'neo4j/mapping/node_mixin'
require 'neo4j/mapping/relationship_mixin'
require 'neo4j/node_mixin'
require 'neo4j/relationship_mixin'
require 'neo4j/mapping/class_methods/rule'

# rails
require 'rails/railtie'
require 'active_model'
require 'neo4j/rails/transaction'
require 'neo4j/rails/railtie'
require 'neo4j/rails/validations/uniqueness'
require 'neo4j/rails/model'
require 'neo4j/rails/value'
require 'neo4j/rails/lucene_connection_closer'



# hmm, looks like Enumerator have been moved in some ruby versions
Enumerator = Enumerable::Enumerator unless defined? Enumerator

