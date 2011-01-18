module Neo4j


  # By including this mixing on a node class one can add migrations to it.
  # Each class has a unique db version.
  #
  # ==== Example
  #
  #  class Person
  #    include Neo4j::NodeMixin
  #    include MigrationMixin
  #    rule :all  # adding the method all to make it possible to find all nodes of this class
  #  end
  #
  #  Person.migration 1, :split_property do
  #    up do
  #      all.each_raw do |node|
  #          node[:given_name] = node[:name].split[0]
  #          node[:surname]    = node[:name].split[1]
  #          node[:name]       = nil
  #        end
  #    end
  #
  #    down do
  #      all.each_raw do |node|
  #       node[:name]       = "#{node[:given_name]} #{node[:surname]}"
  #       node[:surename]   = nil
  #       node[:given_name] = nil
  #      end
  #    end
  #  end
  #
  # Notice that the up and down methods are evaluated in the context of the class (where the all method is defined
  # if using the rule :all).
  #
  module MigrationMixin
    extend ActiveSupport::Concern

    included do
      extend Neo4j::Migrations
    end

    module ClassMethods
      def migrate!(version=nil)
        _migrate!(self, migration_meta_node, version)
      end

      # The node that holds the db version property
      def migration_meta_node
        Neo4j::Mapping::Rule.rule_node_for(self).rule_node
      end

      # Remote all migration and set migrate_to = nil and set the current version to nil
      def reset_migrations!
        @migrations = nil
        @migrate_to = nil
        Neo4j::Transaction.run do
          migration_meta_node[:db_version] = nil
        end
      end
    end

  end


end
