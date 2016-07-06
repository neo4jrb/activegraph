require 'active_support/concern'
require 'neo4j/migrations/helpers/id_property'
require 'neo4j/migration'

namespace :neo4j do
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
  task migrate: :environment do
    Rake::Task['neo4j:migrate:all'].invoke
  end

  namespace :migrate do
    desc 'Run all pending migrations'
    task all: :environment do
      runner = Neo4j::Migrations::Runner.new
      runner.all
    end

    desc 'Run a migration given its VERSION'
    task up: :environment do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.up version
    end

    desc 'Revert a migration given its VERSION'
    task down: :environment do
      version = ENV['VERSION'] || fail(ArgumentError, 'VERSION is required')
      runner = Neo4j::Migrations::Runner.new
      runner.down version
    end

    desc 'Print a report of migrations status'
    task status: :environment do
      runner = Neo4j::Migrations::Runner.new
      runner.status
    end
  end

  desc 'Rollbacks migrations given a STEP number'
  task :rollback, :environment do
    steps = (ENV['STEP'] || 1).to_i
    runner = Neo4j::Migrations::Runner.new
    runner.rollback(steps)
  end
end
