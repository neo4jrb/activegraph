
module Neo4j


  # Keeps configuration for neo4j.
  #
  # Neo4j::Config[:storage_path]:: is used for locating the neo4j database on the filesystem.
  # Neo4j::Config[:rest_port]:: used by the REST extension for starting a web server on a port
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
          :rest_port => 9123
        }
      end

     
      # Yields the configuration.
      #
      # ==== Block parameters
      # c<Hash>:: The configuration parameters.
      #
      # ==== Examples
      # Neo4j::Config.use do |config|
      # config[:storage_path] = '/var/neo4j'
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
      # key<Object>:: The key to set the parameter for.
      # val<Object>:: The value of the parameter.
      #
      def []=(key, val)
        (@configuration ||= setup)[key] = val
      end


      # Gets the the value of a config entry
      #
      # ==== Parameters
      # key<Object>:: The key of the config entry value we want
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
      # Object:: The value of the removed entry.
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
      # key<Object>:: The key to retrieve the parameter for.
      # default<Object>::
      # The default value to return if the parameter is not set.
      #
      # ==== Returns
      # Object:: The value of the configuration parameter or the default.
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
      # Hash:: The config as a hash.
      #
      # :api: public
      def to_hash
        @configuration
      end

      # Returns the config as YAML.
      #
      # ==== Returns
      # String:: The config as YAML.
      #
      # :api: public
      def to_yaml
        require "yaml"
        @configuration.to_yaml
      end
    end
  end

end