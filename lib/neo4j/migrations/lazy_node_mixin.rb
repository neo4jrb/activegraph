module Neo4j

  module Migrations

    # Overrides the init_on_load method so that it will check if any migration is needed.
    # The init_on_create method is also overridden so that it sets the version to the latest migration number
    # when a new node is created.
    #
    # Migration will take place if needed when the node is loaded.
    #
    module LazyNodeMixin
      def self.included(base)
        base.extend Neo4j::Migrations::ClassMethods
        base.property :_db_version if base.respond_to?(:property)
      end


      def migrate!
        self.class._migrate!(self._java_node, self)
      end

      def init_on_create(*)
        super
        # set the db version to the current
        self[:_db_version] = self.class.migrate_to
      end

      def init_on_load(*) # :nodoc:
        super
        migrate!
        # this if for Neo4j::Rails::Model which keeps the properties in this variable
        @properties.clear if instance_variable_defined? :@properties
      end

      def db_version
        self[:_db_version]
      end
    end

  end
end
