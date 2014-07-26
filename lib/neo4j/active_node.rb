module Neo4j

  # Makes Neo4j nodes and relationships behave like active record objects.
  # By including this module in your class it will create a mapping for the node to your ruby class
  # by using a Neo4j Label with the same name as the class. When the node is loaded from the database it
  # will check if there is a ruby class for the labels it has.
  # If there Ruby class with the same name as the label then the Neo4j node will be wrapped
  # in a new object of that class.
  #
  # = ClassMethods
  # * {Neo4j::ActiveNode::Labels::ClassMethods} defines methods like: <tt>index</tt> and <tt>find</tt>
  # * {Neo4j::ActiveNode::Persistence::ClassMethods} defines methods like: <tt>create</tt> and <tt>create!</tt>
  # * {Neo4j::ActiveNode::Property::ClassMethods} defines methods like: <tt>property</tt>.
  #
  # @example Create a Ruby wrapper for a Neo4j Node
  #   class Company
  #      include Neo4j::ActiveNode
  #      property :name
  #   end
  #   company = Company.new
  #   company.name = 'My Company AB'
  #   Company.save
  #
  module ActiveNode
    extend ActiveSupport::Concern
    extend ActiveModel::Naming

    include ActiveModel::Conversion
    include ActiveModel::Serializers::Xml
    include ActiveModel::Serializers::JSON

    include Neo4j::ActiveNode::Initialize
    include Neo4j::ActiveNode::Identity
    include Neo4j::ActiveNode::IdProperty
    include Neo4j::ActiveNode::Persistence
    include Neo4j::ActiveNode::SerializedProperties
    include Neo4j::ActiveNode::Property
    include Neo4j::ActiveNode::Labels
    include Neo4j::ActiveNode::Validations
    include Neo4j::ActiveNode::Callbacks
    include Neo4j::ActiveNode::Rels
    include Neo4j::ActiveNode::HasN
    include Neo4j::ActiveNode::Query

    def wrapper
      self
    end

    def neo4j_obj
      _persisted_node || raise("Tried to access native neo4j object on a non persisted object")
    end

    module ClassMethods
      def neo4j_session_name (name)
        @neo4j_session_name = name
      end

      def neo4j_session
        if @neo4j_session_name
          Neo4j::Session.named(@neo4j_session_name) || raise("#{self.name} is configured to use a neo4j session named #{@neo4j_session_name}, but no such session is registered with Neo4j::Session")
        else
          Neo4j::Session.current
        end
      end
    end

    included do
      self.include_root_in_json = true


      def self.i18n_scope
        :neo4j
      end

      def self.inherited(other)
        inherited_indexes(other) if self.respond_to?(:indexed_properties)
        attributes.each_pair do |k,v|
          other.attributes[k] = v
        end
        Neo4j::ActiveNode::Labels.add_wrapped_class(other)
        super
      end

      def self.inherited_indexes(other)
       return if indexed_properties.nil?
       self.indexed_properties.each {|property| other.index property }
      end

      Neo4j::Session.on_session_available do |_|
        name = Neo4j::Config[:id_property]
        type = Neo4j::Config[:id_property_type]
        value = Neo4j::Config[:id_property_type_value]
        if (name && type && value)
          id_property(name, type => value)
        end
      end

    end
  end
end
