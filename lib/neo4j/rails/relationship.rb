module Neo4j
  module Rails
    class Relationship
      include Neo4j::RelationshipMixin

      attr_reader :type

      index :_classname

      # Initialize a Node with a set of properties (or empty if nothing is passed)
      def initialize(*args)
        @type, @start_node, @end_node, attributes = args
        reset_attributes
        self.attributes = attributes if attributes.is_a?(Hash)
      end

      def to_s
        if start_node.nil?
          "START NODE NIL"
        elsif end_node.nil?
          "END NODE NIL"
        else
          "id: #{self.object_id}  @start_node: #{start_node.object_id}/#{start_node.persisted?} @end_node: #{end_node.object_id}/#{end_node.persisted?} type:#{@type}"
        end
      end
      
      def id
        _java_rel.nil? || neo_id.nil? ? nil : neo_id.to_s
      end

      def start_node
        if persisted?
          _java_rel.start_node
        else
          @start_node
        end
      end

      def end_node
        if persisted?
          _java_rel.end_node
        else
          @end_node
        end
      end

      def del
        _java_rel.del
      end

      def reset_attributes
        @properties = {}
      end

      def valid_relationships?(*)
        true
      end
      # --------------------------------------
      # Public Class Methods
      # --------------------------------------
      class << self
        # NodeMixin overwrites the #new class method but it saves it as orig_new
        # Here, we just get it back to normal
        alias :new :orig_new

        def entity_load(id)
          Neo4j::Relationship.load(id)
        end


        def rule(*)
        end

        def _all
          _indexer.find(:_classname => self)
        end
        
        def load(*ids) # TODO Copied from finders.rb
          result = ids.map { |id| entity_load(id) }
          if ids.length == 1
            result.first
          else
            result
          end
        end

      end

    end


    Relationship.class_eval do
      extend ActiveModel::Translation
      include RelPersistence # handles how to save, create and update the model
      include Attributes # handles how to save and retrieve attributes
      include Mapping::Property # allows some additional options on the #property class method
      include Serialization # enable to_xml and to_json
#      include Timestamps # handle created_at, updated_at timestamp properties
      include Validations # enable validations
      include Callbacks # enable callbacks
      include Finders # ActiveRecord style find
    end

  end
end