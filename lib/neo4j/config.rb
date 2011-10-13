
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
  # <tt>:enable_rules</tt>::   default true, if false the _all relationship to all instances will not be created and custom rules will not be available.
  # <tt>:identity_map</tt>::   default false, See Neo4j::IdentityMap
  #
  class Config
    # This code is copied from merb-core/config.rb.
    class << self

      # The location of the default configuration file
      def default_file
        @default_file ||= File.expand_path(File.join(File.dirname(__FILE__), "..", "..",  "config", "neo4j", "config.yml"))
      end

      # You can keep all the configuration in your own yaml file
      # Also deletes all old configurations.
      def default_file=(file_path)
        @configuration = nil
        @defaults = nil
        @default_file = File.expand_path(file_path)
      end

      # Returns the hash of default config values for neo4j.
      #
      # ==== Returns
      # Hash:: The defaults for the config.
      def defaults
        @defaults ||= YAML.load_file(default_file)
      end

      # Returns a Java HashMap used by the Java Neo4j API as configuration for the GraphDatabase
      def to_java_map
        map = java.util.HashMap.new
        to_hash.each_pair do |k, v|
          case v
            when TrueClass
              map[k.to_s] = "YES"
            when FalseClass
              map[k.to_s] = "NO"
            when String, Fixnum, Float
              map[k.to_s] = v.to_s
            # skip list and hash values - not accepted by the Java Neo4j API
          end
        end
        map
      end


      # Returns the expanded path of the Config[:storage_path] property
      def storage_path
        File.expand_path(self[:storage_path])
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

      # Sets up the configuration to use the default.
      #
      # ==== Returns
      # The a new configuration using default values as a hash.
      #
      def setup()
        @configuration = defaults.with_indifferent_access #nested_under_indifferent_access
        @configuration.merge!(defaults)
        @configuration
      end


      # Returns the configuration as a hash.
      #
      # ==== Returns
      # The config as a hash.
      #
      def to_hash
        @configuration ||= setup
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