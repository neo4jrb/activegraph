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
require 'neo4j/active_rel/rel_wrapper'
require 'neo4j/active_node/node_wrapper'
require 'neo4j/shared/type_converters'
require 'neo4j/shared/rel_type_converters'
require 'neo4j/type_converters'
require 'neo4j/paginated'

require 'neo4j/shared/callbacks'
require 'neo4j/shared/property'
require 'neo4j/shared/persistence'
require 'neo4j/shared/validations'
require 'neo4j/shared/identity'
require 'neo4j/shared/serialized_properties'
require 'neo4j/shared'

require 'neo4j/active_rel/callbacks'
require 'neo4j/active_rel/initialize'
require 'neo4j/active_rel/property'
require 'neo4j/active_rel/persistence'
require 'neo4j/active_rel/validations'
require 'neo4j/active_rel/query'
require 'neo4j/active_rel/related_node'
require 'neo4j/active_rel/types'
require 'neo4j/active_rel'

require 'neo4j/active_node/query_methods'
require 'neo4j/active_node/query/query_proxy_methods'
require 'neo4j/active_node/query/query_proxy_find_in_batches'
require 'neo4j/active_node/labels'
require 'neo4j/active_node/id_property'
require 'neo4j/active_node/callbacks'
require 'neo4j/active_node/initialize'
require 'neo4j/active_node/property'
require 'neo4j/active_node/persistence'
require 'neo4j/active_node/validations'
require 'neo4j/active_node/rels'
require 'neo4j/active_node/reflection'
require 'neo4j/active_node/has_n'
require 'neo4j/active_node/has_n/association'
require 'neo4j/active_node/query/query_proxy'
require 'neo4j/active_node/query'
require 'neo4j/active_node/scope'
require 'neo4j/active_node'

require 'neo4j/active_node/orm_adapter'
if defined?(Rails)
  require 'rails/generators'
  require 'rails/generators/neo4j_generator'
end
