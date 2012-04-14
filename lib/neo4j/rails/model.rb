module Neo4j
  module Rails
    # Makes Neo4j nodes and relationships behave like active record objects.
    # That means for example that you don't have to care about transactions since they will be
    # automatically be created when needed. Validation, Callbacks etc. are also supported.
    #
    # @example Traverse
    #
    #   class Person < Neo4j::Rails::Model
    #   end
    #
    #   person = Person.find(...)
    #   person.outgoing(:foo) << Person.create
    #   person.save!
    #   person.outgoing(:foo).depth(:all)...
    #   person.outgoing(:friends).map{|f| f.outgoing(:knows).to_a}.flatten
    #
    # @example Declared Relationships: has_n and has_one
    #
    #   class Person < Neo4j::Rails::Model
    #   end
    #
    #   class Person
    #      has_n(:friends).to(Person)
    #      has_n(:employed_by)
    #   end
    #
    #   Person.new.foo << other_node
    #   Person.friends.build(:name => 'kalle')
    #
    # @example Declared Properties and Index
    #
    #   class Person < Neo4j::Rails::Model
    #     property :name
    #     property :age, :type => Fixnum, :index => :exact
    #   end
    #
    #   Person.create(:name => 'kalle', :age => 42, :undeclared_prop => 3.14)
    #   Person.find_by_age(42)
    #
    # @example Callbacks
    #
    #   class Person < Neo4j::Rails::Model
    #     before_save :do_something
    #     def do_something
    #     end
    #   end
    #
    # = Class Method Modules
    # * {Neo4j::Rails::Persistence::ClassMethods} defines methods like: <tt>create</tt> and <tt>destroy_all</tt>
    # * {Neo4j::Rails::Attributes::ClassMethods} defines the <tt>property</tt> and <tt>columns</tt> methods.
    # * {Neo4j::Rails::NestedAttributes::ClassMethods} defines <tt>accepts_nested_attributes_for</tt>
    # * {Neo4j::Rails::HasN::ClassMethods} defines <tt>has_n</tt> and <tt>has_one</tt>
    # * {Neo4j::Rails::Finders::ClassMethods} defines <tt>find</tt>
    # * {Neo4j::Rails::Compositions::ClassMethods} defines <tt>composed_of</tt> method
    # * {Neo4j::Rails::AcceptId::ClassMethods} defines <tt>accepts_id_for</tt> method.
    #
    class Model
      extend ActiveModel::Translation

      include Neo4j::NodeMixin
      include ActiveModel::Dirty # track changes to attributes
      include ActiveModel::MassAssignmentSecurity # handle attribute hash assignment
      include ActiveModel::Observing # enable observers
      include Neo4j::Rails::Identity
      include Neo4j::Rails::Persistence # handles how to save, create and update the model
      include Neo4j::Rails::NodePersistence # handles how to save, create and update the model
      include Neo4j::Rails::Attributes # handles how to save and retrieve attributes and override the property class method
      include Neo4j::Rails::NestedAttributes
      include Neo4j::Rails::HasN # allows some additional options on the #property class method
      include Neo4j::Rails::Serialization # enable to_xml and to_json
      include Neo4j::Rails::Validations # enable validations
      include Neo4j::Rails::Callbacks # enable callbacks
      include Neo4j::Rails::Timestamps # handle created_at, updated_at timestamp properties
      include Neo4j::Rails::Finders # ActiveRecord style find
      include Neo4j::Rails::Relationships # for none persisted relationships
      include Neo4j::Rails::Compositions
      include Neo4j::Rails::AcceptId
      include Neo4j::Rails::Relationships

      # --------------------------------------
      # Public Class Methods
      # --------------------------------------
      class << self

        ##
        # Determines whether to use Time.local (using :local) or Time.utc (using :utc) when pulling
        # dates and times from the database. This is set to :local by default.
        # @api public
        def default_timezone
          @default_timezone || :local
        end

        # @api public
        def default_timezone=(zone)
          @default_timezone = zone
        end

        # Set the i18n scope to overwrite ActiveModel.
        #
        # @return [ Symbol ] :neo4j
        # @api public
        def i18n_scope
          :neo4j
        end
      end
    end
  end
end