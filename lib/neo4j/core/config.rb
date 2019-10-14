module Neo4j
  module Core
    module Config
      def self.wrapping_level(level = nil)
        if level.nil?
          @wrapping_level || :core_entity
        else
          @wrapping_level = level
        end
      end
    end
  end
end
