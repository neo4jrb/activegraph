module Neo
  # This class holds and represents a connection to a Neo database. It is inspired by ActiveRecord::Base::Connection
  class Connection
    include Singleton
    attr_reader :neo
    
    # TODO: Implement
    def connected?
      true
    end
    
    # Returns a connection object which is connected
    def self.establish_connection
      return instance
    end
    
    
    def initialize
      @neo = EmbeddedNeo.new("var/tmp")
    end
    
    def disconnect
      @neo.shutdown
    end
  end
end