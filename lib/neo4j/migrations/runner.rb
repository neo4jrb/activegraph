module Neo4j
  module Migrations
    class Runner
      STATUS_TABLE_FORMAT = '%-10s %-20s %s'.freeze
      SEPARATOR = '--------------------------------------------------'.freeze
      FILE_MISSING = '**** file missing ****'.freeze
      STATUS_TABLE_HEADER = ['Status'.freeze, 'Migration ID'.freeze, 'Migration Name'.freeze].freeze
      UP_MESSAGE = 'up'.freeze
      DOWN_MESSAGE = 'down'.freeze

      def initialize
        @up_versions = SchemaMigration.all.pluck(:migration_id)
      end

      def all
        migration_files.each do |migration_file|
          next if @up_versions.include?(migration_file.version)
          migrate_up(migration_file)
        end
      end

      def up(version)
        migration_file = find_by_version!(version)
        return if @up_versions.include?(version)
        migrate_up(migration_file)
      end

      def down(version)
        migration_file = find_by_version!(version)
        return unless @up_versions.include?(version)
        migrate_down(migration_file)
      end

      def rollback(steps)
        @up_versions.sort.reverse.first(steps).each do |version|
          down(version)
        end
      end

      def status
        output STATUS_TABLE_FORMAT, *STATUS_TABLE_HEADER
        output SEPARATOR
        all_migrations.each do |version|
          status = @up_versions.include?(version) ? UP_MESSAGE : DOWN_MESSAGE
          migration_file = find_by_version(version)
          migration_name = migration_file ? migration_file.class_name : FILE_MISSING
          output STATUS_TABLE_FORMAT, status, version, migration_name
        end
      end

      private

      def migrate_up(migration_file)
        migration_message(migration_file, 'running', 'migrated') do
          migration = migration_file.create
          migration.migrate(:up)
        end
      end

      def migrate_down(migration_file)
        migration_message(migration_file, 'reverting', 'reverted') do
          migration = migration_file.create
          migration.migrate(:down)
        end
      end

      def migration_message(migration, running_message, complete_message)
        output "== #{migration.version} #{migration.class_name}: #{running_message}... ========="
        yield
        output "== #{migration.version} #{migration.class_name}: #{complete_message} ========="
      end

      def output(*string_format)
        puts format(*string_format) unless ENV['silenced']
      end

      def find_by_version!(version)
        find_by_version(version) || fail(UnknownMigrationVersionError, "No such migration #{version}")
      end

      def find_by_version(version)
        migration_files.find { |file| file.version == version }
      end

      def all_migrations
        (@up_versions + files_versions).uniq.sort
      end

      def files_versions
        migration_files.map(&:version)
      end

      def migration_files
        files.map { |file_path| MigrationFile.new(file_path) }
      end

      def files
        Dir[files_path].sort
      end

      def files_path
        Rails.root.join('db', 'neo4j', 'migrate', '*.rb')
      end
    end
  end
end
