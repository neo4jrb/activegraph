module Neo4j
  module Rails

    # Includes the Neo4j::NodeMixin and adds ActiveRecord/Model like behaviour.
    # That means for example that you don't have to care about transactions since they will be
    # automatically be created when needed.
    #
    # ==== Included Mixins
    #
    # * Neo4j::Rails::Persistence :: handles how to save, create and update the model
    # * Neo4j::Rails::Attributes :: handles how to save and retrieve attributes
    # * Neo4j::Rails::Mapping::Property :: allows some additional options on the #property class method
    # * Neo4j::Rails::Serialization :: enable to_xml and to_json
    # * Neo4j::Rails::Timestamps :: handle created_at, updated_at timestamp properties
    # * Neo4j::Rails::Validations :: enable validations
    # * Neo4j::Rails::Callbacks :: enable callbacks
    # * Neo4j::Rails::Finders :: ActiveRecord style find
    # * Neo4j::Rails::Relationships :: handles persisted and none persisted relationships.
    # * Neo4j::Rails::Compositions :: see Neo4j::Rails::Compositions::ClassMethods, similar to http://api.rubyonrails.org/classes/ActiveRecord/Aggregations/ClassMethods.html
    # * ActiveModel::Observing # enable observers, see Rails documentation.
    # * ActiveModel::Translation - class mixin
    #
    # ==== Traversals
    # This class only expose a limited set of traversals.
    # If you want to access the raw java node to do traversals use the _java_node.
    #
    #   class Person < Neo4j::Rails::Model
    #   end
    #
    #   person = Person.find(...)
    #   person._java_node.outgoing(:foo).depth(:all)...
    #
    # ==== has_n and has_one
    #
    # The has_n and has_one relationship accessors returns objects of type Neo4j::Rails::Relationships::RelsDSL
    # and Neo4j::Rails::Relationships::NodesDSL which behaves more like the Active Record relationships.
    # Notice that unlike Neo4j::NodeMixin new relationships are kept in memory until @save@ is called.
    #
    # ==== Callbacks
    #
    # The following callbacks are supported :validation, :create, :destroy, :save, :update.
    # It works with before, after and around callbacks, see the Rails documentation.
    # Notice you can also do callbacks using the Neo4j::Rails::Callbacks module (check the Rails documentation)
    #
    class Model
      include Neo4j::NodeMixin


      # Initialize a Node with a set of properties (or empty if nothing is passed)
      def initialize(attributes = {})
        @properties_before_type_cast=java.util.HashMap.new
        reset_attributes
        clear_relationships
        self.attributes = attributes if attributes.is_a?(Hash)
        yield self if block_given?
      end

      def id
        neo_id.nil? ? nil : neo_id.to_s
      end

      def hash
        persisted? ? _java_entity.neo_id.hash : super
      end

      def to_param
        persisted? ? neo_id.to_s : nil
      end


      # Returns an Enumerable of all (primary) key attributes
      # or nil if model.persisted? is false
      def to_key
        persisted? ? [id] : nil
      end

      def reject_if?(proc_or_symbol, attr)
        return false if proc_or_symbol.nil?
        if proc_or_symbol.is_a?(Symbol)
          meth = method(proc_or_symbol)
          meth.arity == 0 ? meth.call : meth.call(attr)
        else
          proc_or_symbol.call(attr)
        end
      end

      def to_model
        self
      end

      def ==(other)
        new? ? self.__id__ == other.__id__ : @_java_node == (other)
      end

      def reachable_from_ref_node?
        Neo4j::Algo.all_path(self.class.ref_node_for_class, self).outgoing(self.class).outgoing(:_all).count > 0
      end

      def attribute_missing(method_id, *args, &block)
        method_name = method_id.method_name
        if property?(method_name)
          self[method_name]
        else
          super
        end
      end

      ##
      # :method: outgoing
      #
      # Similar to Neo4j::Traversal#outgoing but returns depth one only outgoing relationship
      # which may not all be persisted.
      # For only traversing persisted outgoing relationship of any depth or more advanced traversals, use
      # the wrapped Java node instead.
      #
      # ==== Examples
      #
      #   person.outgoing(:friends) << other_person
      #   person.save!
      #
      #   person.outgoing(:friends).map{|f| f.outgoing(:knows).to_a}.flatten
      #
      # ==== Examples
      #
      #   Neo4j::Transaction.run do
      #     person._java_node.outgoing(:friends) << other_person
      #   end
      #
      #   person._java_node.outgoing(:friends).outgoing(:knows).depth(4)
      #
      # Notice you can also declare outgoing relationships with the #has_n and #has_one class method.
      #
      # See Neo4j::Rails::Relationships#outgoing
      # See Neo4j::Traversal#outgoing (when using it from the _java_node)


      ##
      # :method: incoming
      #
      # Returns incoming relationship of depth one which may not all be persisted.
      # See #outgoing


      ##
      # :method: rels
      #
      # Returns both incoming and outgoing relationships which may not all be persisted.
      # If you only want to find persisted relationships: @node._java_node.rels@
      #
      # See Neo4j::Rails::Relationships#rels
      # See Neo4j::Rels#rels or Neo4j::Rels
      #

      ##
      # :method: []
      #
      # Returns a property of this node, which may or may not have been declared with the class property method.
      # Similar to Neo4j::Property#[] but can return not persisted properties as well.

      ##
      # :method: []=
      #
      # Sets any property on the node.
      # Similar to Neo4j::Property#[]= but you must call the #save method to persist the property.

      ##
      # :singleton-method: property
      #
      # See Neo4j::Rails::Mapping::Property::ClassMethods#property

      ##
      # :singleton-method: has_one
      #
      # Generates a has_one methods which returns an object of type Neo4j::Rails::Relationships::NodesDSL
      # and a has_one method postfixed @_rel@ which return a Neo4j::Rails::Relationships::RelsDSL
      #
      # See also Neo4j::Rails::Mapping::Property::ClassMethods#has_one
      #

      ##
      # :singleton-method: columns
      #
      # Returns all defined properties as an array

      ##
      # :singleton-method: has_n
      #
      # Generates a has_n method which returns an object of type Neo4j::Rails::Relationships::NodesDSL
      # and a has_n method postfixed @_rel@ which return a Neo4j::Rails::Relationships::RelsDSL
      #
      # See also Neo4j::Rails::Mapping::Property::ClassMethods#has_n
      #


      # --------------------------------------
      # Public Class Methods
      # --------------------------------------
      class << self
        # NodeMixin overwrites the #new class method but it saves it as orig_new
        # Here, we just get it back to normal
        alias :new :orig_new

        def transaction(&block)
          Neo4j::Rails::Transaction.run do |tx|
            block.call(tx)
          end
        end

        def entity_load(id)
          Neo4j::Node.load(id)
        end

        ##
        # Determines whether to use Time.local (using :local) or Time.utc (using :utc) when pulling
        # dates and times from the database. This is set to :local by default.
        def default_timezone
          @default_timezone || :local
        end

        def default_timezone=(zone)
          @default_timezone = zone
        end

        def accepts_nested_attributes_for(*attr_names)
          options = attr_names.pop if attr_names[-1].is_a?(Hash)

          attr_names.each do |association_name|
            # Do some validation that we have defined the relationships we want to nest
            rel = self._decl_rels[association_name.to_sym]
            raise "No relationship declared with has_n or has_one with type #{association_name}" unless rel
            raise "Can't use accepts_nested_attributes_for(#{association_name}) since it has not defined which class it has a relationship to, use has_n(#{association_name}).to(MyOtherClass)" unless rel.target_class

            if rel.has_one?
              send(:define_method, "#{association_name}_attributes=") do |attributes|
                update_nested_attributes(association_name.to_sym, attributes, options)
              end
            else
              send(:define_method, "#{association_name}_attributes=") do |attributes|
                if attributes.is_a?(Array)
                  attributes.each do |attr|
                    update_nested_attributes(association_name.to_sym, attr, options)
                  end
                else
                  attributes.each_value do |attr|
                    update_nested_attributes(association_name.to_sym, attr, options)
                  end
                end
              end
            end

          end
        end

        # When multitenancy is used, node should be findable only from current ref node.
        def findable?(entity)
          entity.is_a? self and entity.reachable_from_ref_node?
        end

        # Set the i18n scope to overwrite ActiveModel.
        #
        # @return [ Symbol ] :neo4j
        def i18n_scope
          :neo4j
        end
      end
    end

    Model.class_eval do
      extend ActiveModel::Translation

      include Persistence # handles how to save, create and update the model
      include Attributes # handles how to save and retrieve attributes
      include Mapping::Property # allows some additional options on the #property class method
      include Serialization # enable to_xml and to_json
      include Validations # enable validations
      include Callbacks # enable callbacks
      include Timestamps # handle created_at, updated_at timestamp properties
      include ActiveModel::Observing # enable observers
      include Finders # ActiveRecord style find
      include Relationships # for none persisted relationships
      include Compositions
      include AcceptId
    end
  end
end
