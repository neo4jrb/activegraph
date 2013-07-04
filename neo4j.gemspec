# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "neo4j"
  s.version = "2.2.3"
  s.platform = "java"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andreas Ronge"]
  s.date = "2013-03-18"
  s.description = "You can think of Neo4j as a high-performance graph engine with all the features of a mature and robust database.\nThe programmer works with an object-oriented, flexible network structure rather than with strict and static tables \nyet enjoys all the benefits of a fully transactional, enterprise-strength database.\nIt comes included with the Apache Lucene document database.\n"
  s.email = "andreas.ronge@gmail.com"
  s.executables = ["neo4j-shell", "neo4j-jars", "neo4j-upgrade"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["bin/neo4j-jars", "bin/neo4j-shell", "bin/neo4j-upgrade", "lib/generators", "lib/neo4j", "lib/neo4j.rb", "lib/orm_adapter", "lib/generators/neo4j", "lib/generators/neo4j.rb", "lib/generators/neo4j/model", "lib/generators/neo4j/model/model_generator.rb", "lib/generators/neo4j/model/templates", "lib/generators/neo4j/model/templates/model.erb", "lib/neo4j/paginated.rb", "lib/neo4j/rails", "lib/neo4j/tasks", "lib/neo4j/type_converters", "lib/neo4j/version.rb", "lib/neo4j/rails/accept_id.rb", "lib/neo4j/rails/attributes.rb", "lib/neo4j/rails/callbacks.rb", "lib/neo4j/rails/column.rb", "lib/neo4j/rails/compositions.rb", "lib/neo4j/rails/finders.rb", "lib/neo4j/rails/ha_console", "lib/neo4j/rails/has_n.rb", "lib/neo4j/rails/identity.rb", "lib/neo4j/rails/model.rb", "lib/neo4j/rails/nested_attributes.rb", "lib/neo4j/rails/node_persistance.rb", "lib/neo4j/rails/observer.rb", "lib/neo4j/rails/persistence.rb", "lib/neo4j/rails/rack_middleware.rb", "lib/neo4j/rails/rails.rb", "lib/neo4j/rails/railtie.rb", "lib/neo4j/rails/relationship.rb", "lib/neo4j/rails/relationship_persistence.rb", "lib/neo4j/rails/relationships", "lib/neo4j/rails/serialization.rb", "lib/neo4j/rails/timestamps.rb", "lib/neo4j/rails/transaction.rb", "lib/neo4j/rails/tx_methods.rb", "lib/neo4j/rails/validations", "lib/neo4j/rails/validations.rb", "lib/neo4j/rails/versioning", "lib/neo4j/rails/ha_console/railtie.rb", "lib/neo4j/rails/relationships/node_dsl.rb", "lib/neo4j/rails/relationships/relationships.rb", "lib/neo4j/rails/relationships/rels_dsl.rb", "lib/neo4j/rails/relationships/storage.rb", "lib/neo4j/rails/validations/associated.rb", "lib/neo4j/rails/validations/non_nil.rb", "lib/neo4j/rails/validations/uniqueness.rb", "lib/neo4j/rails/versioning/versioning.rb", "lib/neo4j/tasks/neo4j.rb", "lib/neo4j/tasks/upgrade_v2", "lib/neo4j/tasks/upgrade_v2/lib", "lib/neo4j/tasks/upgrade_v2/upgrade_v2.rake", "lib/neo4j/tasks/upgrade_v2/lib/upgrade_v2.rb", "lib/neo4j/type_converters/serialize_converter.rb", "lib/orm_adapter/adapters", "lib/orm_adapter/adapters/neo4j.rb", "config/locales", "config/neo4j", "config/locales/en.yml", "config/neo4j/config.yml", "README.rdoc", "CHANGELOG", "CONTRIBUTORS", "Gemfile", "neo4j.gemspec"]
  s.homepage = "http://github.com/andreasronge/neo4j/tree"
  s.rdoc_options = ["--quiet", "--title", "Neo4j.rb", "--line-numbers", "--main", "README.rdoc", "--inline-source"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubyforge_project = "neo4j"
  s.rubygems_version = "1.8.24"
  s.summary = "A graph database for JRuby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<orm_adapter>, [">= 0.0.3"])
      s.add_runtime_dependency(%q<activemodel>, ["< 5", ">= 3.0.0", "~> 4.0.0.beta"])
      s.add_runtime_dependency(%q<railties>, ["< 5", ">= 3.0.0", "~> 4.0.0.beta"])
      s.add_runtime_dependency(%q<neo4j-wrapper>, ["= 2.3.0"])
      s.add_runtime_dependency(%q<rails-observers>, [">= 0.1.1"])
    else
      s.add_dependency(%q<orm_adapter>, [">= 0.0.3"])
      s.add_dependency(%q<activemodel>, ["< 5", ">= 3.0.0", "~> 4.0.0.beta"])
      s.add_dependency(%q<railties>, ["< 5", ">= 3.0.0", "~> 4.0.0.beta"])
      s.add_dependency(%q<neo4j-wrapper>, ["= 2.3.0"])
      s.add_dependency(%q<rails-observers>, [">= 0.1.1"])
    end
  else
    s.add_dependency(%q<orm_adapter>, [">= 0.0.3"])
    s.add_dependency(%q<activemodel>, ["< 5", ">= 3.0.0", "~> 4.0.0.beta"])
    s.add_dependency(%q<railties>, ["< 5", ">= 3.0.0", "~> 4.0.0.beta"])
    s.add_dependency(%q<neo4j-wrapper>, ["= 2.3.0"])
    s.add_dependency(%q<rails-observers>, [">= 0.1.1"])
  end
end
