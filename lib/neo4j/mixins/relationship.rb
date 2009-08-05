module Neo4j


  # A module that can be mixed in like a Neo4j::NodeMixin
  # It wraps the Neo4j Relationship class.
  #
  module RelationshipMixin
    extend TransactionalMixin

    attr_reader :internal_r

    # Initialize the Relationship object with specified java org.neo4j.api.core.Relationship object
    # Expects at least one parameter.
    # 
    # ==== Parameters
    # param1<org.neo4j.api.core.Relationship>:: the internal java relationship object
    # 
    # :api: public
    def initialize(*args)
      init_with_rel(args[0])

      # must call super with no arguments so that chaining of initialize method will work
      super()
    end


    # Inits this node with the specified java neo node
    #
    # :api: private
    def init_with_rel(node)
      @internal_r = node
      self.classname = self.class.to_s unless @internal_r.hasProperty("classname")
      $NEO_LOGGER.debug {"loading relationship '#{self.class.to_s}' id #{@internal_r.getId()}"}
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
      neo_node = node
      neo_node = node.internal_node if node.respond_to?(:internal_node)
      id = @internal_r.getOtherNode(neo_node).getId
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


    # Deletes this relationship.
    #
    # :api: public
    def delete
      Neo4j.event_handler.relationship_deleted(self)
      type = @internal_r.getType().name()
      @internal_r.delete

      # TODO not sure if we need to do it on both start and end node ...
#      start_node.class.indexer.on_relationship_deleted(start_node, type) unless start_node.nil?
      end_node.class.indexer.on_relationship_deleted(end_node, type) unless end_node.nil?
    end


    # Sets a neo property on this relationship. This property does not have to be declared first.
    # If the value of the property is nil the property will be removed.
    #
    # ==== Parameters
    # name<String>:: the name of the property to be set
    # value<Object>:: the value of the property to be set.
    #
    # :api: public
    def set_property(key, value)
      if value.nil?
        remove_property(key)
      else
        @internal_r.setProperty(key, value)
      end
    end

    # Checks if the given neo property exists.
    #
    # ==== Returns
    # true if the property exists
    #
    # :api: public
    def property?(key)
      @internal_r.hasProperty(key)
    end

    # Returns the value of the given neo property.
    #
    # ==== Returns
    # the value of the property or nil if the property does not exist
    #
    # :api: public
    def get_property(key)
      return nil unless self.property?(key)
      @internal_r.getProperty(key)
    end

    # Removes the property from this relationship
    # For more information see JavaDoc PropertyContainer#removeProperty
    #
    # ==== Returns
    # true if the property was removed, false otherwise
    #
    # :api: public
    def remove_property(name)
      !@internal_r.removeProperty(name).nil?
    end

    # Returns a hash of all properties.
    #
    # ==== Returns
    # Hash:: property key and property value
    #
    # :api: public
    def props
      ret = {"id" => neo_relationship_id}
      iter = @internal_r.getPropertyKeys.iterator
      while (iter.hasNext) do
        key = iter.next
        ret[key] = @internal_r.getProperty(key)
      end
      ret
    end

    # Returns the given property
    # Same as #get_property
    #
    # :api: public
    def [](name)
      get_property(name.to_s)
    end

    # Sets the given property to a given value
    # Same as #set_property
    #
    # :api: public
    def []=(name, value)
      set_property(name.to_s, value)
    end

    def classname
      get_property('classname')
    end

    def classname=(value)
      set_property('classname', value)
    end


    # Returns a hash of all properties.
    #
    # ==== Returns
    # Hash:: property key and property value
    #
    # :api: public
    def props
      ret = {"id" => neo_relationship_id}
      iter = @internal_r.getPropertyKeys.iterator
      while (iter.hasNext) do
        key = iter.next
        ret[key] = @internal_r.getProperty(key)
      end
      ret
    end


    # Returns the unique relationship id.
    # Can be used to load it with the Neo4j#load_relationship method
    #
    # :api: public
    def neo_relationship_id
      @internal_r.getId()
    end


    def eql?(o)
      o.kind_of?(RelationshipMixin) && o.internal_r == internal_r
    end

    def ==(o)
      eql?(o)
    end

    def hash
      internal_node.hashCode
    end

    transactional :initialize, :property?, :set_property, :get_property, :delete

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
