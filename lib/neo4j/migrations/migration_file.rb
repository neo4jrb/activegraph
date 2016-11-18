module Neo4j
  module Migrations
    class MigrationFile
      attr_reader :file_name, :symbol_name, :class_name, :version

      def initialize(file_name)
        @file_name = file_name
        extract_data!
      end

      def create(options = {})
        require @file_name
        class_name.constantize.new(@version, options)
      end

      private

      def extract_data!
        @version, @symbol_name = File.basename(@file_name, '.rb').split('_', 2)
        @class_name = @symbol_name.camelize
      end
    end
  end
end
