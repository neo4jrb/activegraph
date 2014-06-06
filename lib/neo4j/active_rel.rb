module Neo4j

  # Makes Neo4j relationships behave like active record objects.
  # By including this module in your class it will create a mapping for the relationship to your ruby class
  # by setting the rel_type with the same name as the class. When the relationship is loaded from the database it
  # will check if there is a ruby class for the rel_type it has.
  # If there Ruby class with the same name as the rel_type then the Neo4j relationship will be wrapped
  # in a new object of that class.
  #
  # A lot of behaviour can be inherited from ActiveNode, therefore
  # TODO: abstract out a shared ActiveNeo module
  #
  # = ClassMethods
  # * {Neo4j::ActiveRel::RelType::ClassMethods} defines methods like: <tt>all</tt> and <tt>find</tt>
  # * {Neo4j::ActiveRel::Persistence::ClassMethods} defines methods like: <tt>create</tt> and <tt>save</tt>
  # * {Neo4j::ActiveNode::Property::ClassMethods} defines methods like: <tt>property</tt>.
  #
  # @example Create a Ruby wrapper for a Neo4j Node
  #   class Score
  #      include Neo4j::ActiveRel
  #      property :value
  #   end
  #   score = Score.new
  #   score.value = 8
  #   score.save #will throw an error if score.start_node and score.end_node are not set/able to persist
  #
  module ActiveRel
    extend ActiveSupport::Concern
    extend ActiveModel::Naming

    include ActiveAttr::Attributes
    include ActiveAttr::MassAssignment
    include ActiveAttr::TypecastedAttributes
    include ActiveAttr::AttributeDefaults
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include ActiveModel::Serializers::Xml
    include ActiveModel::Serializers::JSON

    include Neo4j::ActiveRel::Initialize
    include Neo4j::ActiveNode::Identity
    include Neo4j::ActiveRel::Persistence
    include Neo4j::ActiveNode::Property
    include Neo4j::ActiveRel::RelType
    include Neo4j::ActiveNode::Callbacks
    include Neo4j::ActiveNode::Validations
    #include Neo4j::ActiveRel::Validations

    def wrapper
      self
    end

    def neo4j_obj
      _persisted_rel || raise("Tried to access native neo4j object on a none persisted object")
    end

    def start_node
      persisted? ? neo4j_obj.start_node : @start_node
    end

    def end_node
      persisted? ? neo4j_obj.end_node : @end_node
    end

    def start_node=(node)
      !persisted? ? @start_node = node : raise("Tried to set start_node on a persisted relationship")
    end

    def end_node=(node)
      !persisted? ? @end_node = node : raise("Tried to set end_node on a persisted relationship")
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
      validate :surrounded?, on: :create
      before_create :ensure_surroundings_persisted

      def self.inherited(other)
        attributes.each_pair do |k,v|
          other.attributes[k] = v
        end
        Neo4j::ActiveRel::RelType.add_wrapped_class(other)
        super
      end
    end

    def surrounded?
      puts 'surrounded? called'

      unless persisted? || (start_node && end_node)
        errors.add(:start_node, "must be set") if !start_node
        errors.add(:end_node, "must be set") if !end_node
        return false
      end
      true
    end

    def ensure_surroundings_persisted
      unless persisted? || (start_node.save && end_node.save)
        errors.add(:start_node, start_node.errors) if !start_node.errors.empty?
        errors.add(:end_node, end_node.errors) if !end_node.errors.empty?
        return false
      end
      true
    end
  end
end
