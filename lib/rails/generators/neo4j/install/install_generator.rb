require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

class Neo4j::Generators::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  desc "Install neo4j orm"

  def copy_initializer

    # ORM Config
    if rails_5?
      template 'neo4j_rails5.rb', 'config/initializers/neo4j.rb'
    else
      inject_into_file 'config/application.rb', File.read("../../templates/neo4j_rails4.rb"), :after => '[:password]'
    end

    # we are using JRuby - use Threads !
    gsub_file "config/environments/production.rb", "# config.threadsafe!", "config.threadsafe!"
  end

  protected

  def rails_5?
    Rails::VERSION::MAJOR == 5
  end

end