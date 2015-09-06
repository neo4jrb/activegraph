require 'neo4j/migration'

namespace :neo4j do
  desc 'Run a script against the database to perform system-wide changes'
  task :migrate, [:task_name, :subtask] => :environment do |_, args|
    path = Rake.original_dir
    migration_task = args[:task_name]
    task_name_constant = migration_task.split('_').map(&:capitalize).join('')
    begin
      migration_class = "Neo4j::Migration::#{task_name_constant}".constantize
    rescue NameError
      load File.join(path, 'db', 'neo4j-migrate', "#{migration_task}.rb")
      migration_class = "#{task_name_constant}".constantize
    end
    migration = migration_class.new(path)

    subtask = args[:subtask]
    if subtask
      migration.send(subtask)
    else
      migration.migrate
    end
  end
end
