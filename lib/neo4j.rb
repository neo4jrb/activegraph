require 'neo4j/version'

#require "delegate"
#require "time"
#require "set"
#
#require "active_support/core_ext"
#require "active_support/json"
#require "active_support/inflector"
#require "active_support/time_with_zone"

require "neo4j-core"
require "active_model"
require 'active_support/concern'
require 'active_support/core_ext/class/attribute.rb'

require 'active_attr'
require 'neo4j/config'
require 'neo4j/wrapper'
require 'neo4j/type_converters'
require "neo4j/active_node/labels"
require 'neo4j/active_node/identity'
require 'neo4j/active_node/id_property'
require 'neo4j/active_node/callbacks'
require 'neo4j/active_node/initialize'
require 'neo4j/active_node/property'
require 'neo4j/active_node/persistence'
require 'neo4j/active_node/validations'
require 'neo4j/active_node/rels'
require 'neo4j/active_node/has_n'
require 'neo4j/active_node/has_n/decl_rel'
require 'neo4j/active_node/has_n/nodes'
require 'neo4j/active_node/query/query_proxy'
require 'neo4j/active_node/query'
require 'neo4j/active_node/quick_query'
require 'neo4j/active_node/serialized_properties'
require 'neo4j/paginated'
require 'neo4j/active_node'

require 'neo4j/active_node/orm_adapter'
require 'rails/generators'
require 'rails/generators/neo4j_generator'

