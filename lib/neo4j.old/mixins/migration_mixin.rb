module Neo4j


  # By including this mixing on a node class one can add migrations to it.
  # Adds a db_version attribute on the class including this mixin.
  # 
  module MigrationMixin

    # Returns the current version of the database of the class including this Mixin.
    #
    def db_version
      Neo4j::Transaction.run {self[:db_version] || 0}
    end


    # Force one or more migrations to occur if not already done yet.
    # Will check the current db_version with the given 'to_version' and perform
    # migrations. If the 'to_version' parameter is not given then it will upgrade the
    # database with all migrations it can find.
    #
    # === Parameters
    # to_version:: the version we want to migrate to, if not given then all migrations will be run
    # verbose:: if it should print out information of which migration is run
    #
    def migrate!(to_version=nil, verbose = false)
      return if self.class.migrations.nil? || self.class.migrations.empty?


      # which version should we go to if to_version was not provided ?
      to_version ||= self.class.migrations.keys.sort.reverse[0]
      puts "Migration: Curr ver #{db_version} need upgrade to version #{to_version}" if verbose

      # do we need to migrate ?
      return if db_version == to_version

      # ok, so we are running some migrations
      if (db_version < to_version)
        upgrade( (db_version+1).upto(to_version).collect { |ver| self.class.migrations[ver] }, verbose )
      else
        downgrade( db_version.downto(to_version+1).collect { |ver| self.class.migrations[ver] }, verbose )
      end
    end

    # Running the up method on the given migrations.
    #
    # === Parameters
    # migrations:: an enumerable of Migration objects
    def upgrade(migrations, verbose=false)
      migrations.each do |m|
        puts "Running upgrade migration #{m.version} - #{m.name}"  if verbose
        m.up_migrator.execute(self, m.version, &m.up_block)
      end
    end

    # Running the down method on the given migrations.
    #
    # === Parameters
    # migrations:: an enumerable of Migration objects
    def downgrade(migrations, verbose=false)
      migrations.each do |m|
        puts "Running downgrade migration #{m.version} - #{m.name}" if verbose
        m.down_migrator.execute(self, m.version-1, &m.down_block)
      end
    end

    def self.included(c) # :nodoc:
      c.extend Neo4j::MigrationMixin::ClassMethods
    end

    module ClassMethods
      attr_accessor :migrations, :migrate_to

      # Specifies a migration to be performed.
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
        @migrations ||= {}
        migration = Migration.new(version, name)
        migration.instance_eval(&block)
        @migrations[version] = migration
      end

      # This is used for lazy migration. It stores the version that we want to upgrade to but does not perform the migrations.
      # Only when the node is being loaded from the database  (Neo4j::NodeMixin#init_with_node) then
      # it will check and see if one or more migration is needed to be performed.
      #
      def migrate!(to_version=nil)
        @migrate_to = to_version
      end
    end

    # This is the context in which the Migrations DSL are evaluated in.
    class Migration < Struct.new(:version, :name)
      attr_reader :up_block, :down_block, :up_migrator, :down_migrator

      # Specifies a code block which is run when the migration is upgraded.
      #
      # === Parameters
      # migrator:: Default Neo4j::MigrationMixin::Migrator - used to execute the block
      def up(migrator = Migrator, &block)
        @up_block = block
        @up_migrator = migrator
      end

      # Specifies a code block which is run when the migration is upgraded.
      #
      # === Parameters
      # migrator:: Default Neo4j::MigrationMixin::Migrator - used to execute the block
      def down(migrator = Migrator, &block)
        @down_block = block
        @down_migrator = migrator
      end

      def to_s
        "Migration version: #{version}, name: #{name}"
      end
    end

    # Responsible for running a migration
    class Migrator
      class << self
        # Runs given migration block. If successful it will set the property
        # ':db_version' on the given context.
        #
        # === Parameters
        # context:: the context on which the block is evaluated in
        # version:: optional, if given then will set the property db_version on the context
        def execute(context, version=nil, &block)
          context.instance_eval &block
          Neo4j::Transaction.run { context[:db_version] = version} if version
        end
      end
    end
  end


  # Overrides the init method so that it will check if any migration is needed.
  # Migration might take place when the node is loaded.
  #
  module LazyMigrationMixin
    def init_with_node(java_node) # :nodoc:
      super # call Neo4j::NodeMixin#init_with_node
      migrate! self.class.migrate_to # for lazy migrations
    end
  end
end

