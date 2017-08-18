module Neo4j
  module Migrations
    class Runner
      STATUS_TABLE_FORMAT = '%-10s %-20s %s'.freeze
      SEPARATOR = '--------------------------------------------------'.freeze
      FILE_MISSING = '**** file missing ****'.freeze
      STATUS_TABLE_HEADER = ['Status'.freeze, 'Migration ID'.freeze, 'Migration Name'.freeze].freeze
      UP_MESSAGE = 'up'.freeze
      DOWN_MESSAGE = 'down'.freeze
      INCOMPLETE_MESSAGE = 'incomplete'.freeze
      MIGRATION_RUNNING = {up: 'running'.freeze, down: 'reverting'.freeze}.freeze
      MIGRATION_DONE = {up: 'migrated'.freeze, down: 'reverted'.freeze}.freeze

      def initialize(options = {})
        @silenced = options[:silenced] || !!ENV['MIGRATIONS_SILENCED']
        label = SchemaMigration.mapped_label
        label.create_constraint(:migration_id, type: :unique) unless label.constraint?(:migration_id)
        @schema_migrations = SchemaMigration.all.to_a
        @up_versions = SortedSet.new(@schema_migrations.map(&:migration_id))
      end

      def all
        handle_incomplete_states!
        migration_files.each do |migration_file|
          next if up?(migration_file.version)
          migrate(:up, migration_file)
        end
      end

      def up(version)
        handle_incomplete_states!
        migration_file = find_by_version!(version)
        return if up?(version)
        migrate(:up, migration_file)
      end

      def down(version)
        handle_incomplete_states!
        migration_file = find_by_version!(version)
        return unless up?(version)
        migrate(:down, migration_file)
      end

      def rollback(steps)
        handle_incomplete_states!
        @up_versions.to_a.reverse.first(steps).each do |version|
          down(version)
        end
      end

      def pending_migrations
        all_migrations.select { |migration| !up?(migration) }
      end

      def complete_migration_versions
        @schema_migrations.map(&:migration_id)
      end

      def mark_versions_as_complete(versions)
        Neo4j::ActiveBase.new_query
                         .with('{versions} AS versions').params(versions: versions).break
                         .unwind(version: :versions).break
                         .merge('(:`Neo4j::Migrations::SchemaMigration` {migration_id: version})')
                         .exec
      end

      def status
        output STATUS_TABLE_FORMAT, *STATUS_TABLE_HEADER
        output SEPARATOR
        all_migrations.each do |version|
          status = migration_status(version)
          migration_file = find_by_version(version)
          migration_name = migration_file ? migration_file.class_name : FILE_MISSING
          output STATUS_TABLE_FORMAT, status, version, migration_name
        end
      end

      def resolve(version)
        SchemaMigration.find_by!(migration_id: version).update!(incomplete: false)
        output "Migration #{version} resolved."
      end

      def reset(version)
        SchemaMigration.find_by!(migration_id: version).destroy
        output "Migration #{version} reset."
      end

      private

      def migration_status(version)
        return DOWN_MESSAGE unless up?(version)
        incomplete_states.find { |v| v.migration_id == version } ? INCOMPLETE_MESSAGE : UP_MESSAGE
      end

      def handle_incomplete_states!
        return unless incomplete_states.any?
        incomplete_versions = incomplete_states.map(&:migration_id)
        fail MigrationError, <<-MSG
There are migrations struck in an incomplete states, that could not be fixed automatically:
#{incomplete_versions.join('\n')}
This can happen when there's a critical error inside a migration.

If you think they were was completed correctly, run:

#{task_migration_messages('resolve', incomplete_versions)}

If you want to reset and run the migration again, run:

#{task_migration_messages('reset', incomplete_versions)}

MSG
      end

      def task_migration_messages(type, versions)
        versions.map do |version|
          "rake neo4j:migrate:#{type} VERSION=#{version}"
        end.join("\n")
      end

      def up?(version)
        @up_versions.include?(version)
      end

      def migrate(direction, migration_file)
        migration_message(direction, migration_file) do
          migration = migration_file.create(silenced: @silenced)
          migration.migrate(direction)
        end
      end

      def migration_message(direction, migration)
        output_migration_message "#{migration.version} #{migration.class_name}: #{MIGRATION_RUNNING[direction]}..."
        time = format('%.4fs', yield)
        output_migration_message "#{migration.version} #{migration.class_name}: #{MIGRATION_DONE[direction]} (#{time})"
        output ''
      end

      def output(*string_format)
        puts format(*string_format) unless @silenced
      end

      def output_migration_message(message)
        out = "== #{message} "
        tail = '=' * [0, 80 - out.length].max
        output "#{out}#{tail}"
      end

      def find_by_version!(version)
        find_by_version(version) || fail(UnknownMigrationVersionError, "No such migration #{version}")
      end

      def find_by_version(version)
        migration_files.find { |file| file.version == version }
      end

      def all_migrations
        @up_versions + migration_files_versions
      end

      def incomplete_states
        @incomplete_states ||= SortedSet.new(@schema_migrations.select(&:incomplete?))
      end

      delegate :migration_files, :migration_files_versions, to: :class

      class <<self
        def migration_files_versions
          migration_files.map!(&:version)
        end

        def migration_files
          files.map! { |file_path| MigrationFile.new(file_path) }
        end

        def latest_migration
          migration_files.last
        end

        def files
          Dir[files_path].sort
        end

        private

        def files_path
          app_root.join('db', 'neo4j', 'migrate', '*.rb')
        end

        def app_root
          defined?(Rails) ? Rails.root : Pathname.new('.')
        end
      end
    end
  end
end
