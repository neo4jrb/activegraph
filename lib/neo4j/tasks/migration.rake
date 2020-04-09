require 'rake'
require 'active_support/concern'
require 'neo4j/migration'

if !defined?(Rails) && !Rake::Task.task_defined?('environment')
  desc 'Run a script against the database to perform system-wide changes'
  task :environment do
    require 'neo4j/session_manager'
    require 'ostruct'
    neo4j_url = ENV['NEO4J_URL'] || 'http://localhost:7474'
    $LOAD_PATH.unshift File.dirname('./')
    Neo4j::ActiveBase.on_establish_session do
      type = neo4j_url =~ /^bolt/ ? :bolt : :http
      Neo4j::SessionManager.open_neo4j_session(type, neo4j_url)
    end
  end
end

namespace :neo4j do
  task :allow_migrations do
    Neo4j::Migrations.currently_running_migrations = true
  end
  desc 'Run a script against the database to perform system-wide changes'
  task :legacy_migrate, [:task_name, :subtask] => :environment do |_, args|
    path = Rake.original_dir
    migration_task = args[:task_name]
    task_name_constant = migration_task.split('_').map(&:capitalize).join('')
    begin
      migration_class = "Neo4j::Migration::#{task_name_constant}".constantize
    rescue NameError
      load File.join(path, 'db', 'neo4j-migrate', "#{migration_task}.rb")
      migration_class = task_name_constant.to_s.constantize
    end
    migration = migration_class.new(path)

    subtask = args[:subtask]
    if subtask
      migration.send(subtask)
    else
      migration.migrate
    end
  end

  desc 'A shortcut for neo4j::migrate::all'
  task :migrate do
    Rake::Task['neo4j:migrate:all'].invoke
  end

  # TODO: Make sure these tasks don't run in versions of Neo4j before 3.0
  namespace :schema do
    SCHEMA_YAML_PATH = 'db/neo4j/schema.yml'
    SCHEMA_YAML_COMMENT = <<COMMENT
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of ActiveNode to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.yml definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using neo4j:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

COMMENT

    def check_neo4j_version_3
      if Neo4j::ActiveBase.current_session.version > '3.0.0'
        yield
      else
        puts 'WARNING: This task does not work for versions of Neo4j before 3.0.0'
      end
    end

    desc 'Creates a db/neo4j/schema.yml file which represents the indexes / constraints in the Neo4j DB'
    task dump: :environment do
      check_neo4j_version_3 do
        require 'neo4j/migrations/schema'

        schema_data = Neo4j::Migrations::Schema.fetch_schema_data(Neo4j::ActiveBase.current_session)

        runner = Neo4j::Migrations::Runner.new
        schema_data[:versions] = runner.complete_migration_versions.sort

        FileUtils.mkdir_p(File.dirname(SCHEMA_YAML_PATH))
        File.open(SCHEMA_YAML_PATH, 'w') { |file| file << SCHEMA_YAML_COMMENT + schema_data.to_yaml }

        puts "Dumped updated schema file to #{SCHEMA_YAML_PATH}"
      end
    end

    desc "Loads a db/neo4j/schema.yml file into the database\nOptionally removes schema elements which aren't in the schema.yml file (defaults to false)"
    task :load, [:remove_missing] => :environment do |_t, args|
      check_neo4j_version_3 do
        require 'neo4j/migrations/schema'

        args.with_defaults(remove_missing: false)
        schema_data = YAML.safe_load(File.read(SCHEMA_YAML_PATH), [Symbol])
        Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:puts))
        Neo4j::ActiveBase.run_transaction do
          Neo4j::Migrations::Schema.synchronize_schema_data(Neo4j::ActiveBase.current_session, schema_data, args[:remove_missing])
        end
        Neo4j::ActiveBase.run_transaction do
          runner = Neo4j::Migrations::Runner.new
          runner.mark_versions_as_complete(schema_data[:versions]) # Run in test mode?
        end
      end
    end
  end

  namespace :migrate do
    desc 'Run all pending migrations'
    task all: [:allow_migrations, :environment] do
      runner = Neo4j::Migrations::Runner.new
      runner.all

      Rake::Task['neo4j:schema:dump'].invoke
    end

    desc 'Run a migration given its VERSION'
    task up: [:allow_migrations, :environment] do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.up version

      Rake::Task['neo4j:schema:dump'].invoke
    end

    desc 'Revert a migration given its VERSION'
    task down: [:allow_migrations, :environment] do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.down version

      Rake::Task['neo4j:schema:dump'].invoke
    end

    desc 'Print a report of migrations status'
    task status: [:allow_migrations, :environment] do
      runner = Neo4j::Migrations::Runner.new
      runner.status
    end

    desc 'Resolve an incomplete version state'
    task resolve: [:allow_migrations, :environment] do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.resolve version
    end

    desc 'Resolve an incomplete version state'
    task reset: [:allow_migrations, :environment] do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.reset version
    end
  end

  desc 'Rollbacks migrations given a STEP number'
  task rollback: [:allow_migrations, :environment] do
    steps = (ENV['STEP'] || 1).to_i
    runner = Neo4j::Migrations::Runner.new
    runner.rollback(steps)

    Rake::Task['neo4j:schema:dump'].invoke
  end

  # Temporary to help people change to 8.0
  desc 'Generates a migration for the specified constraint/index and label/property combination.'
  task :generate_schema_migration, :index_or_constraint, :label, :property_name do |_t, args|
    index_or_constraint, label, property_name = args.values_at(:index_or_constraint, :label, :property_name)

    if !%w(index constraint).include?(index_or_constraint)
      fail "Invalid schema element type: #{index_or_constraint} (should be either `index` or `constraint`)"
    end
    fail 'Label must be specified' if label.blank?
    fail 'Property name must be specified' if property_name.blank?

    migration_class_name = "ForceCreate#{label.camelize}#{property_name.camelize}#{index_or_constraint.capitalize}".gsub('::', '').underscore.camelize

    require 'fileutils'
    FileUtils.mkdir_p('db/neo4j/migrate')
    path = File.join('db/neo4j/migrate', "#{DateTime.now.utc.strftime('%Y%m%d%H%M%S')}_#{migration_class_name.underscore}.rb")

    content = <<-CONTENT
class #{migration_class_name} < Neo4j::Migrations::Base
  def up
    add_#{index_or_constraint} #{label.to_sym.inspect}, #{property_name.to_sym.inspect}, force: true
  end

  def down
    drop_#{index_or_constraint} #{label.to_sym.inspect}, #{property_name.to_sym.inspect}
  end
end
CONTENT

    File.open(path, 'w') { |f| f << content }

    puts "Generated #{path}"
  end
end
