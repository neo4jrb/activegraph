require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

module Neo4j
  module Generators
    class Migration < ::Neo4j::Generators::Base
      def create_migration_file
        real_file_name = "#{Time.zone.now.strftime('%Y%m%d%H%M%S')}_#{file_name.parameterize}"
        @migration_class_name = file_name.camelize

        if args[0] == 'force_add_index'
          @content = "force_add_index #{args[1].to_s.classify.to_sym.inspect}, #{args[2].to_sym.inspect}"
        end

        template 'migration.erb', File.join('db/neo4j/migrate', real_file_name)
      end
    end
  end
end
