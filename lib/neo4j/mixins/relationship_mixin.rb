module Neo4j


  # A module that can be mixed in like a Neo4j::NodeMixin
  # It wraps the Neo4j Relationship class.
  #
  module RelationshipMixin
    extend Forwardable

    attr_reader :_java_node

    def_delegators :@_java_node, :[]=, :[], :property?, :props, :update, :neo_id, :del, :start_node, :end_node, :other_node, :relationship_type, :wrapper

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
      @_java_node = node
      node[:_classname] = self.class.to_s unless node.property?(:_classname)
      $NEO_LOGGER.debug {"loading relationship '#{self.class.to_s}' id #{@_java_node.getId()}"}
    end


    def eql?(o)
      o.kind_of?(RelationshipMixin) && o.internal_r == internal_r
    end

    def ==(o)
      eql?(o)
    end

    def hash
      _java_node.hashCode
    end

    #
    # Adds classmethods in the ClassMethods module
    #
    def self.included(c)
      c.extend ClassMethods
    end

    module ClassMethods

      # Not implemented yet marshal of relationship properties, (unlike NodeMixin properties)
      # Returns false
      def marshal?(key)
        false
      end

      def property(*props)
        props.each do |prop|
          define_method(prop) do
            self[prop]
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            self[prop] = value
          end
        end

      end
    end
  end
end
