
module Neo4j


  # == Keeps configuration for neo4j
  #
  # The most important configuration is <tt>Neo4j::Config[:storage_path]</tt> which is used to
  # locate where the neo4j database is stored on the filesystem.
  # If this directory is empty then a new database will be created, otherwise it will use the
  # database from that directory.
  #
  # ==== Default Configurations
  # <tt>:storage_path</tt>::   default <tt>tmp/neo4j</tt> where the database is stored
  # <tt>:timestamps</tt>::     default <tt>true</tt> for Rails Neo4j::Model - if timestamps should be used when saving the model
  # <tt>:lucene</tt>::         default hash keys: <tt>:fulltext</tt>, <tt>:exact</tt> configuration how the lucene index is stored
  # <tt>:converters</tt>::     defines which converters should be used before writing and reading to neo4j, see Neo4j::TypeConverters
  #
  class Config
    # This code is copied from merb-core/config.rb.
    class << self
      # Returns the hash of default config values for neo4j
      #
      # ==== Returns
      # Hash:: The defaults for the config.
      def defaults
        @defaults ||= {
          :storage_path => 'tmp/neo4j',
          :timestamps => true,
          :lucene => {
                  :fulltext =>  {"provider" => "lucene", "type" => "fulltext" },
                  :exact =>  {"provider" => "lucene", "type" => "exact" }}
        }
      end

     
      # Yields the configuration.
      #
      # ==== Block parameters
      # c :: The configuration parameters, a hash.
      #
      # ==== Examples
      # Neo4j::Config.use do |config|
      #   config[:storage_path] = '/var/neo4j'
      # end
      #
      # ==== Returns
      # nil
      def use
        @configuration ||= {}
        yield @configuration
        nil
      end
      
      
      # Set the value of a config entry.
      #
      # ==== Parameters
      # key :: The key to set the parameter for.
      # val :: The value of the parameter.
      #
      def []=(key, val)
        (@configuration ||= setup)[key] = val
      end


      # Gets the the value of a config entry
      #
      # ==== Parameters
      # key:: The key of the config entry value we want
      #
      def [](key)
        (@configuration ||= setup)[key]
      end


      # Remove the value of a config entry.
      #
      # ==== Parameters
      # key<Object>:: The key of the parameter to delete.
      #
      # ==== Returns
      # The value of the removed entry.
      #
      def delete(key)
        @configuration.delete(key)
      end


      # Remove all configuration. This can be useful for testing purpose.
      #
      #
      # ==== Returns
      # nil
      #
      def delete_all
        @configuration = nil
      end


      # Retrieve the value of a config entry, returning the provided default if the key is not present
      #
      # ==== Parameters
      # key:: The key to retrieve the parameter for.
      # default::The default value to return if the parameter is not set.
      #
      # ==== Returns
      # The value of the configuration parameter or the default.
      #
      def fetch(key, default)
        @configuration.fetch(key, default)
      end

      # Sets up the configuration
      #
      # ==== Returns
      # The configuration as a hash.
      #
      def setup()
        @configuration = {}
        @configuration.merge!(defaults)
        @configuration
      end


      # Returns the configuration as a hash.
      #
      # ==== Returns
      # The config as a hash.
      #
      def to_hash
        @configuration
      end

      # Returns the config as YAML.
      #
      # ==== Returns
      # The config as YAML.
      #
      def to_yaml
        require "yaml"
        @configuration.to_yaml
      end
    end
  end

end