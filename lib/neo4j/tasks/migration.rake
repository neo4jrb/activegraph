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

  namespace :migrate do
    desc 'Run all pending migrations'
    task all: [:allow_migrations, :environment] do
      runner = Neo4j::Migrations::Runner.new
      runner.all
    end

    desc 'Run a migration given its VERSION'
    task up: [:allow_migrations, :environment] do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.up version
    end

    desc 'Revert a migration given its VERSION'
    task down: [:allow_migrations, :environment] do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.down version
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

    migration_class_name = "ForceCreate#{label.camelize}#{property_name.camelize}#{index_or_constraint.capitalize}".gsub('::', '')

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
