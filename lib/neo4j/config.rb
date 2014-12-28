module Neo4j


  # == Keeps configuration for neo4j
  #
  # == Configurations keys
  #
  class Config

    DEFAULT_FILE = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', 'neo4j', 'config.yml'))

    class << self

      # @return [Fixnum] The location of the default configuration file.
      def default_file
        @default_file ||= DEFAULT_FILE
      end

      # Sets the location of the configuration YAML file and old deletes configurations.
      #
      # @param [String] file_path represent the path to the file.
      def default_file=(file_path)
        delete_all
        @defaults = nil
        @default_file = File.expand_path(file_path)
      end

      # @return [Hash] the default file loaded by yaml
      def defaults
        require 'yaml'
        @defaults ||= ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(default_file))
      end

      # Reads from the default_file if configuration is not set already
      # @return [Hash] the configuration
      def get_or_setup_configuration
        @configuration ||= setup
      end

      # @return [Hash] the configuration
      def configuration
        @configuration || {}
      end

      # Yields the configuration
      #
      # @example
      #   Neo4j::Config.use do |config|
      #     config[:storage_path] = '/var/neo4j'
      #   end
      #
      # @return nil
      # @yield config
      # @yieldparam [Neo4j::Config] config - this configuration class
      def use
        @configuration ||= ActiveSupport::HashWithIndifferentAccess.new
        yield @configuration
        nil
      end


      # Sets the value of a config entry.
      #
      # @param [Symbol] key the key to set the parameter for
      # @param val the value of the parameter.
      def []=(key, val)
        get_or_setup_configuration[key.to_s] = val
      end


      # @param [Symbol] key The key of the config entry value we want
      # @return the the value of a config entry
      def [](key)
        get_or_setup_configuration[key.to_s]
      end


      # Remove the value of a config entry.
      #
      # @param [Symbol] key the key of the configuration entry to delete
      # @return The value of the removed entry.
      def delete(key)
        get_or_setup_configuration.delete(key)
      end


      # Remove all configuration. This can be useful for testing purpose.
      #
      # @return nil
      def delete_all
        @configuration = nil
      end


      # @return [Hash] The config as a hash.
      def to_hash
        get_or_setup_configuration.to_hash
      end

      # @return [String] The config as a YAML
      def to_yaml
        get_or_setup_configuration.to_yaml
      end

      # @return The a new configuration using default values as a hash.
      def setup
        @configuration = ActiveSupport::HashWithIndifferentAccess.new
        @configuration.merge!(defaults)
        @configuration
      end

      def class_name_property
        Neo4j::Config[:class_name_property] || :_classname
      end

      def include_root_in_json
        # we use ternary because a simple || will always evaluate true
        Neo4j::Config[:include_root_in_json].nil? ? true : Neo4j::Config[:include_root_in_json]
      end
    end
  end
end
