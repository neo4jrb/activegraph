module Neo4j

  # By including this mixing on a node class one can add migrations to it.
  # Adds a db_version attribute on the class including this mixin.
  # 
  module MigrationMixin

    def db_version
      Neo4j::Transaction.run {self[:db_version] || 0}
    end


    def init_with_node(java_node) # :nodoc:
      super # call Neo4j::NodeMixin#init_with_node
      migrate! self.class.migrate_to # for lazy migrations
    end
    

    def migrate!(to_version=nil)
      return if self.class.migrations.nil? || self.class.migrations.empty?
      puts "Curr version #{db_version}"
      to_version ||= self.class.migrations.keys.sort.reverse[0]
      puts "To version #{to_version}"

      Neo4j::Transaction.new
      # going up or down ?
      if (db_version == to_version)
        puts "Already at version #{to_version}"
      elsif (db_version < to_version)
        Migrator.upgrade( (db_version+1).upto(to_version).collect { |ver| self.class.migrations[ver] }, self )
      else
        Migrator.downgrade( db_version.downto(to_version+1).collect { |ver| self.class.migrations[ver] }, self )
      end
      self[:db_version] = to_version
      Neo4j::Transaction.finish
    end

    def self.included(c) # :nodoc:
      c.extend Neo4j::MigrationMixin::ClassMethods
    end

    module ClassMethods
      attr_accessor :migrations, :migrate_to

      def migration(number, name, &block)
        @migrations ||= {}
        @migrations[number] = {:name => name, :block => block}
      end

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
        def upgrade(migrations, node_context)
          get_blocks(migrations).up_blocks.each {|block| node_context.instance_eval &block}
        end

        def downgrade(migrations, node_context)
          get_blocks(migrations).down_blocks.each { |block| node_context.instance_eval &block}
        end

        def get_blocks(migrations)
          context = Migrator.new
          migrations.each {|m| puts "Running Migration #{m[:name]}"; context.instance_eval &m[:block]}
          context
        end
      end
    end


  end
end

