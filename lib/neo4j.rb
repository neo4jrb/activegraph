require 'forwardable'
require 'time'
require 'date'
require 'tmpdir'

# Rails
require 'rails/railtie'
require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/class/attribute'

require 'active_model'

require 'neo4j-core'
require 'neo4j-wrapper'

require 'neo4j/type_converters/serialize_converter'
require 'neo4j/rails/rails'
require 'neo4j/paginated'

require 'orm_adapter/adapters/neo4j'
Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].each { |ext| load ext } if defined?(Rake) && respond_to?(:namespace)
