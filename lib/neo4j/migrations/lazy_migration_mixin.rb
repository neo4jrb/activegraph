module Neo4j

  # Overrides the init_on_load method so that it will check if any migration is needed.
  # The init_on_create method is also overriden so that it sets the version to the latest migration number
  # when a new node is created.
  #
  # Migration will take place if needed when the node is loaded.
  #
  module LazyMigrationMixin
    extend ActiveSupport::Concern

    included do
      extend Neo4j::Migrations
    end

    module ClassMethods
      # Remote all migration and set migrate_to = nil
      # Does not change the version of nodes.
      def reset_migrations!
        @migrations = nil
        @migrate_to = nil
      end
    end

    def migrate!
      self.class._migrate!(self._java_node, self)
    end

    def init_on_create(*)
      super
      # set the db version to the current
      self[:db_version] = self.class.migrate_to
    end

    def init_on_load(*) # :nodoc:
      super
      migrate!
      # this if for Neo4j::Rails::Model which keeps the properties in this variable
      @properties.clear if instance_variable_defined? :@properties
    end

    def db_version
      self[:db_version]
    end
  end

end