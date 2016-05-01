require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

class Neo4j::Generators::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  desc "Install neo4j orm"

  def copy_initializer
    copy_rake_tasks
    update_threadsafe
    orm_and_config
  end

  protected

  def copy_rake_tasks
    use_template 'db.rake', 'lib/tasks/db.rake'
  end

  def update_threadsafe
    # we are using JRuby - use Threads !
    gsub_file "config/environments/production.rb", "# config.threadsafe!", "config.threadsafe!"
  end

  def orm_and_config
    if rails_5?
      use_template 'neo4j_rails5.rb', 'config/initializers/neo4j.rb'
    else
      inject_to File.read("../../templates/neo4j_rails.rb"), 'config/application.rb', :after => '[:password]'
    end
  end

  def use_template(source, dest)
    template source, dest
  end

  def inject_to(data, dest, options)
    inject_into_file dest, data, options
  end

  def rails_5?
    Rails::VERSION::MAJOR >= 5
  end

end