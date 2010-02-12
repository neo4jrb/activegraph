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


    def init_with_node(java_node) # :nodoc:
      super # call Neo4j::NodeMixin#init_with_node
      migrate! self.class.migrate_to # for lazy migrations
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
      to_version ||= self.class.migrations.keys.sort.reverse[0]
      puts "Migration: Curr ver #{db_version} need upgrade to version #{to_version}" if verbose

      # going up or down ?
      if (db_version == to_version)
        puts "Already at version #{to_version}" if verbose
      elsif (db_version < to_version)
        Migrator.upgrade( (db_version+1).upto(to_version).collect { |ver| self.class.migrations[ver] }, self, verbose )
      else
        Migrator.downgrade( db_version.downto(to_version+1).collect { |ver| self.class.migrations[ver] }, self, verbose )
      end
      self[:db_version] = to_version
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
      #
      def migration(number, name, &block)
        @migrations ||= {}
        @migrations[number] = {:name => name, :block => block}
      end

      # This is used for lazy migration. It stores the version that we want to upgrade to but does not perform the migrations.
      # Only when the node is being loaded from the database  (Neo4j::NodeMixin#init_with_node) then
      # it will check and see if one or more migration is needed to be performed.
      #
      def migrate!(to_version=nil)
        @migrate_to = to_version
      end
    end

    # This is used as both the context for the Migration DSL and running the actual migrations.
    class Migrator # :nodoc:
      attr_reader :up_blocks, :down_blocks

      def up(&block)
        @up_blocks ||= []
        @up_blocks << block
      end

      def down(&block)
        @down_blocks ||= []
        @down_blocks << block
      end

      class << self
        def upgrade(migrations, node_context, verbose)
          get_blocks(migrations, verbose).up_blocks.each {|block| node_context.instance_eval &block}
        end

        def downgrade(migrations, node_context, verbose)
          get_blocks(migrations, verbose).down_blocks.each { |block| node_context.instance_eval &block}
        end

        def get_blocks(migrations, verbose)
          context = Migrator.new
          migrations.each {|m| puts "Running Migration #{m[:name]}" if verbose; context.instance_eval &m[:block]}
          context
        end
      end
    end


  end
end

