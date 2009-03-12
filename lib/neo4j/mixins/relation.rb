module Neo4j


  # A module that can be mixed in like a Neo4j::NodeMixin
  # It wraps the Neo4j Relationship class.
  #
  module RelationMixin
    extend TransactionalMixin

    # Initialize the Relation object with specified java org.neo4j.api.core.Relationship object
    # Expects at least one parameter.
    # 
    # ==== Parameters
    # param1<org.neo4j.api.core.Relationship>:: the internal java relationship object
    # 
    # :api: public
    def initialize(*args)
      Transaction.run {init_with_rel(args[0])} unless Transaction.running?
      init_with_rel(args[0])                   if Transaction.running?

      # must call super with no arguments so that chaining of initialize method will work
      super()
    end


    # Inits this node with the specified java neo node
    #
    # :api: private
    def init_with_rel(node)
      @internal_r = node
      self.classname = self.class.to_s unless @internal_r.hasProperty("classname")
      $NEO_LOGGER.debug {"loading relation '#{self.class.to_s}' id #{@internal_r.getId()}"}
    end

    # :api: public
    def end_node
      id = @internal_r.getEndNode.getId
      Neo4j.instance.find_node id
    end

    # :api: public
    def start_node
      id = @internal_r.getStartNode.getId
      Neo4j.instance.find_node id
    end

    # :api: public
    def other_node(node)
      id = @internal_r.getOtherNode(node).getId
      Neo4j.instance.find_node id
    end

    # Returns the neo relationship type that this relationship is used in.
    # (see java API org.neo4j.api.core.Relationship#getType  and org.neo4j.api.core.RelationshipType)
    #
    # ==== Returns
    # Symbol
    # 
    # :api: public
    def relationship_type
      @internal_r.get_type.name.to_sym
    end
    

    # Deletes the relationship between two nodes.
    # Will fire a RelationshipDeletedEvent on the start_node class.
    #
    # :api: public
    def delete
      type = @internal_r.getType().name()
      @internal_r.delete

      # TODO not sure if we need to do it on both start and end node ...
#      start_node.class.indexer.on_relation_deleted(start_node, type) unless start_node.nil?
      end_node.class.indexer.on_relation_deleted(end_node, type) unless end_node.nil?
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
      def property(*props)
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