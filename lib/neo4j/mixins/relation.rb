  module Neo4j

  #
  # A module that can be mixed in like a Neo4j::NodeMixin
  # It wraps the Neo4j Relationship class.
  #
  module RelationMixin
    extend TransactionalMixin

    def initialize(*args)
      if args.length == 1 and args[0].kind_of?(org.neo4j.api.core.Relationship)
        Transaction.run {init_with_rel(args[0])} unless Transaction.running?
        init_with_rel(args[0])                   if Transaction.running?
      else
        raise ArgumentError.new("This code should not be executed - remove todo")
        Transaction.run {init_without_rel} unless Transaction.running?
        init_without_rel                   if Transaction.running?
      end

      # must call super with no arguments so that chaining of initialize method will work
      super()
    end

    #
    # Inits this node with the specified java neo node
    #
    def init_with_rel(node)
      @internal_r = node
      self.classname = self.class.to_s unless @internal_r.hasProperty("classname")
      $NEO_LOGGER.debug {"loading relation '#{self.class.to_s}' id #{@internal_r.getId()}"}
    end


    #
    # Inits when no neo java node exists. Must create a new neo java node first.
    #
    def init_without_rel
      @internal_r = Neo4j::Neo.instance.create_node
      self.classname = self.class.to_s
      self.class.fire_event RelationshipAddedEvent.new(self)  #from_node, to_node, relation_name, relation_id
      $NEO_LOGGER.debug {"created new node '#{self.class.to_s}' node id: #{@internal_node.getId()}"}
    end

    def end_node
      id = @internal_r.getEndNode.getId
      Neo.instance.find_node id
    end

    def start_node
      id = @internal_r.getStartNode.getId
      Neo.instance.find_node id
    end

    def other_node(node)
      id = @internal_r.getOtherNode(node).getId
      Neo.instance.find_node id
    end

    #
    # Deletes the relationship between two nodes.
    # Will fire a RelationshipDeletedEvent on the start_node class.
    #
    def delete
      type = @internal_r.getType().name()
      start_node.class.fire_event(RelationshipDeletedEvent.new(start_node, end_node, type, @internal_r.getId))
      @internal_r.delete
    end

    def set_property(key,value)
      @internal_r.setProperty(key,value)
    end

    def property?(key)
      @internal_r.hasProperty(key)
    end

    def get_property(key)
      return nil unless self.property?(key)
      @internal_r.getProperty(key)
    end

    def classname
      get_property('classname')
    end

    def classname=(value)
      set_property('classname', value)
    end


    def neo_relation_id
      @internal_r.getId()
    end

    transactional :property?, :set_property, :get_property, :delete

    #
    # Adds classmethods in the ClassMethods module
    #
    def self.included(c)
      c.extend ClassMethods
    end

    module ClassMethods
      def properties(*props)
        props.each do |prop|
          define_method(prop) do
            get_property(prop.to_s)
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            set_property(prop.to_s, value)
          end
        end

      end
    end
  end
end