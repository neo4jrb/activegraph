#require "activesupport/lib/active_support/core_ext/hash/keys.rb"

module Neo4j
  module TypeConverters
    # Serialize using YAML
    #
    # @example Usage from Neo4j::Rails::Model
    #   class Person < Neo4j::Rails::Model
    #     property :stuff, :type => :serialize
    #   end
    #   Person.new(:stuff => {:complex => :things})
    #
    # @see http://rdoc.info/github/andreasronge/neo4j-wrapper/Neo4j/TypeConverters for converters defined in neo4j-wrapper gem (which is included).
    class SerializeConverter
      # serializes to sting
      class << self

        def convert?(type)
          type == :serialize
        end

        def to_java(value)
          return nil unless value
          YAML.dump(value)
        end

        def to_ruby(value)
          # from db, to object
          return nil unless value
          YAML.load(value)
        end

        def index_as
          String
        end
      end
    end
  end
end