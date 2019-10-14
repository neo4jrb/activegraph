namespace :neo4j do
  %i[install start start_no_wait console shell config stop info indexes constraints
     restart reset_yes_i_am_sure change_password enable_auth disable_auth].each do |task_name|
    task task_name do |_, _args|
      puts <<-INFO
  The `neo4j-rake_tasks` gem is no longer a dependency of the `neo4j-core` gem.
  If you would like to use the rake tasks, you will need to explicitly include the `neo4j-rake_tasks` gem in your project.
  Please note that the `neo4j-rake_tasks` gem is only for development and test environments (NOT for production).
  Be sure to require the `neo4j-rake_tasks` gem AFTER the `neo4j-core` and `neo4j` gems.
  For more details see the Neo4j.rb documentation
INFO
    end
  end
end
