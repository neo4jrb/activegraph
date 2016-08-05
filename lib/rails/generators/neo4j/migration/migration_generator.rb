require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

module Neo4j
  module Generators
    class Migration < ::Neo4j::Generators::Base
      include ::Neo4j::Generators::Migration

      def create_migration_file
        migration_template 'migration.erb'
      end
    end
  end
end
