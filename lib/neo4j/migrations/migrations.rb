module Neo4j
  module Migrations

    # Sets the the version we request to migrate to
    # If not set will migrate to the highest possible migration
    def migrate_to=(version)
      @migrate_to = version
    end

    def migrate_to
      @migrate_to
    end

    def latest_migration
      migrations.keys.sort.reverse[0]
    end

    # contains all the migrations defined with the #migration DSL method
    def migrations
      @migrations ||= {}
    end

    # Specifies a migration to be performed.
    # Updates the migrate_to variable so that it will migrate to the latest migration.
    #
    # === Example
    #
    # In the following example the up and down method will be evaluated in the context of a Person node.
    #
    #   Person.migration 1, :my_first_migration do
    #     up { ... }
    #     down { ... }
    #   end
    #
    # See the Neo4j::MigrationMixin::Migration which the DSL is evaluated in.
    #
    def migration(version, name, &block)
      migration   = Migration.new(version, name)
      migration.instance_eval(&block)
      migrations[version] = migration
      self.migrate_to = latest_migration
    end


    def _migrate!(context, meta_node, version=nil) #:nodoc:
      # set the version we want to migrate to if provided
      self.migrate_to = version if version

      # requested to migrate to a version ?
      return if self.migrate_to.nil?

      # which version are we on now ?
      current_version = meta_node[:db_version] || 0

      # do we need to migrate ?
      return if current_version == self.migrate_to
      
      # ok, so we are running some migrations
      if (current_version < self.migrate_to)
        upgrade((current_version+1).upto(self.migrate_to).collect { |ver| migrations[ver] }, context, meta_node)
      else
        downgrade(current_version.downto(self.migrate_to+1).collect { |ver| migrations[ver] }, context, meta_node)
      end
    end

    # Running the up method on the given migrations.
    #
    # === Parameters
    # migrations :: an enumerable of Migration objects
    def upgrade(migrations, context, meta_node)
      migrations.each do |m|
        Neo4j.logger.info "Running upgrade: #{m}"
        m.execute_up(context, meta_node)
      end
    end

    # Running the down method on the given migrations.
    #
    # === Parameters
    # migrations:: an enumerable of Migration objects
    def downgrade(migrations, context, meta_node)
      migrations.each do |m|
        Neo4j.logger.info "Running downgrade: #{m}"
        m.execute_down(context, meta_node)
      end
    end

  end
end

