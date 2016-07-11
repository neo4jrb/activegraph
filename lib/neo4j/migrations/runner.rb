module Neo4j
  module Migrations
    class Runner
      STATUS_TABLE_FORMAT = '%-10s %-20s %s'.freeze
      SEPARATOR = '--------------------------------------------------'.freeze
      FILE_MISSING = '**** file missing ****'.freeze
      STATUS_TABLE_HEADER = ['Status'.freeze, 'Migration ID'.freeze, 'Migration Name'.freeze].freeze
      UP_MESSAGE = 'up'.freeze
      DOWN_MESSAGE = 'down'.freeze
      MIGRATION_RUNNING = {up: 'running'.freeze, down: 'reverting'.freeze}.freeze
      MIGRATION_DONE = {up: 'migrated'.freeze, down: 'reverted'.freeze}.freeze

      def initialize
        @up_versions = SortedSet.new(SchemaMigration.all.pluck(:migration_id))
      end

      def all
        migration_files.each do |migration_file|
          next if up?(migration_file.version)
          migrate(:up, migration_file)
        end
      end

      def up(version)
        migration_file = find_by_version!(version)
        return if up?(version)
        migrate(:up, migration_file)
      end

      def down(version)
        migration_file = find_by_version!(version)
        return unless up?(version)
        migrate(:down, migration_file)
      end

      def rollback(steps)
        @up_versions.to_a.reverse.first(steps).each do |version|
          down(version)
        end
      end

      def status
        output STATUS_TABLE_FORMAT, *STATUS_TABLE_HEADER
        output SEPARATOR
        all_migrations.each do |version|
          status = up?(version) ? UP_MESSAGE : DOWN_MESSAGE
          migration_file = find_by_version(version)
          migration_name = migration_file ? migration_file.class_name : FILE_MISSING
          output STATUS_TABLE_FORMAT, status, version, migration_name
        end
      end

      private

      def up?(version)
        @up_versions.include?(version)
      end

      def migrate(direction, migration_file)
        migration_message(direction, migration_file) do
          migration = migration_file.create
          migration.migrate(direction)
        end
      end

      def migration_message(direction, migration)
        output "== #{migration.version} #{migration.class_name}: #{MIGRATION_RUNNING[direction]}... ========="
        yield
        output "== #{migration.version} #{migration.class_name}: #{MIGRATION_DONE[direction]} ========="
      end

      def output(*string_format)
        puts format(*string_format) unless !!ENV['MIGRATIONS_SILENCED']
      end

      def find_by_version!(version)
        find_by_version(version) || fail(UnknownMigrationVersionError, "No such migration #{version}")
      end

      def find_by_version(version)
        migration_files.find { |file| file.version == version }
      end

      def all_migrations
        @up_versions + files_versions
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
        app_root.join('db', 'neo4j', 'migrate', '*.rb')
      end

      def app_root
        defined?(Rails) ? Rails.root : Pathname.new('.')
      end
    end
  end
end
