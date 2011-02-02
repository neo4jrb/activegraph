module Neo4j

  class << self
    extend Forwardable

    ##
    # Returns the current version of the database.
    # This version has been set by running one or more migrations.
    # The version is stored on the reference node, with property 'db_version'
    # (It Delegates to the Reference Node)
    #
    # ==== See Also
    # Neo4j::Migrations::RefNodeWrapper#db_version
    #
    # :singleton-method: db_version

    ##
    # Force Neo4j.rb to perform migrations
    #
    # ==== See Also
    #
    # Neo4j::Migrations::RefNodeWrapper#migrate!
    #
    # :singleton-method: migrate!

    ##
    # Specifies a single migration.
    # The up and down methods are automatically wrapped in a transaction.
    #
    # === Example
    #
    #   Neo4j.migration 1, :create_articles do
    #    up do
    #      Neo4j.ref_node.rels.outgoing(:colours) << Neo4j.Node.new(:colour => 'red')  << Neo4j.Node.new(:colour => 'blue')
    #    end
    #    down do
    #      Neo4j.ref_node.rels.outgoing(:colours).each {|n| n.del }
    #    end
    #  end
    #
    # ==== See Also
    # Neo4j::Migrations::ClassMethods#migration
    #
    # :singleton-method: migration

    ##
    # Returns all migrations that has been defined.
    #
    # ==== See Also
    # Neo4j::Migrations::ClassMethods#migrations
    #
    # :singleton-method: migrations


    def_delegators :'Neo4j::Migrations::RefNodeWrapper', :db_version, :migrate!, :migrations, :migration

  end
end
