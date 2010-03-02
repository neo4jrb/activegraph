
module Lucene


  #
  # Keeps configuration for lucene.
  # Contains both common configuration for all lucene indexes as well
  # as specific configuration for each index (TODO).
  # This code is copied from merb-core/config.rb.
  #
  # Contains three default configurations (Config.defaults)
  # * :store_on_file:: default false, which will only keep the index in memory
  # * :id_field:: default :id
  # * :storage_path:: where the index is kept on file system if stored as a file (instead of just in memory)
  #
  class Config
    class << self
      # Returns the hash of default config values for lucene.
      #
      # ==== Returns
      # Hash:: The defaults for the config.
      #
      def defaults
        @defaults ||= {
          :store_on_file => false,
          :id_field => :id,
          :storage_path => nil
        }
      end

     
      # Yields the configuration.
      #
      # ==== Block parameters
      # c<Hash>:: The configuration parameters.
      #
      # ==== Examples
      # Lucene::Config.use do |config|
      # config[:in_memory] = true
      # end
      #
      # ==== Returns
      # nil
      #
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
        IndexInfo.delete_all
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
      def to_hash
        @configuration
      end

      # Returns the config as YAML.
      #
      # ==== Returns
      # String:: The config as YAML.
      #
      def to_yaml
        require "yaml"
        @configuration.to_yaml
      end
    end
  end

end