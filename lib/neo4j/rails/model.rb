module Neo4j
  module Rails

    # Includes the Neo4j::NodeMixin and adds ActiveRecord/Model like behaviour.
    # That means for example that you don't have to care about transactions since they will be
    # automatically be created when needed.
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
    #
    class Model
      include Neo4j::NodeMixin


      # Initialize a Node with a set of properties (or empty if nothing is passed)
      def initialize(attributes = {})
        reset_attributes
        clear_relationships
        self.attributes = attributes if attributes.is_a?(Hash)
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
      end
    end

    Model.class_eval do
      extend ActiveModel::Translation

      include Persistence # handles how to save, create and update the model
      include Attributes # handles how to save and retrieve attributes
      include Mapping::Property # allows some additional options on the #property class method
      include Serialization # enable to_xml and to_json
      include Timestamps # handle created_at, updated_at timestamp properties
      include Validations # enable validations
      include Callbacks # enable callbacks
      include ActiveModel::Observing # enable observers
      include Finders # ActiveRecord style find
      include Relationships # for none persisted relationships
    end
  end
end
