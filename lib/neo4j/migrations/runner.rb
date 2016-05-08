module Neo4j
  module Migrations
    class Runner
      def initialize
        @up_versions = SchemaMigration.all.pluck(:migration_id)
      end

      def all
        all_migrations.each do |file|
          version, file_name = *version_and_file_name_by_path(file)
          next if @up_versions.include?(version)
          klass = classify(file_name)
          require file
          migrate_up(version, klass)
        end
      end

      def up(version)
        file = find_by_version!(version)
        return if @up_versions.include?(version)
        _, file_name = *version_and_file_name_by_path(file)
        require file
        migrate_up(version, classify(file_name))
      end

      def down(version)
        file = find_by_version!(version)
        return if @up_versions.include?(version)
        _, file_name = *version_and_file_name_by_path(file)
        require file
        migrate_down(version, classify(file_name))
      end

      def rollback
        fail NotImplementedError
      end

      private

      def classify(string)
        string.split('_').map(&:capitalize).join('')
      end

      def version_and_file_name_by_path(path)
        File.basename(path, '.rb').split('_', 2)
      end

      def migrate_up(version, klass)
        puts "== #{version} #{klass}: running... ========="
        migration = klass.constantize.new(version)
        migration.migrate(:up)
        puts "== #{version} #{klass}: migrated ========="
      end

      def migrate_down(version, klass)
        puts "== #{version} #{klass}: reverting... ========="
        migration = klass.constantize.new(version)
        migration.migrate(:down)
        puts "== #{version} #{klass}: reverted ========="
      end

      def find_by_version!(version)
        all_migrations.find { |file| File.basename(file).starts_with?(version) } ||
          fail("No such migration #{version}")
      end

      def all_migrations
        Dir[Rails.root.join('db', 'neo4j', 'migrate', '*.rb')].sort
      end
    end
  end
end
