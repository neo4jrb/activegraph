module Neo4j::Rails

  class Value
    include Properties
    include org.neo4j.graphdb.Node

    def initialize(wrapper)
      @wrapper = wrapper
      @outgoing_rels = {}  # a hash of all relationship with key type
    end

    def getId
      nil
    end

    def create_relationship_to(other_java_node, java_type)
      outgoing(java_type.name).new(other_java_node)
    end

    def rel(dir, type)
      # TODO incoming not implemented, needed ?
      @outgoing_rels[type.to_s] && @outgoing_rels[type.to_s].rels.first
    end

    def getRelationships(*args)
      type = args[0].name
      outgoing = @outgoing_rels[type]
      return [] unless outgoing
      outgoing.rels
    end

    def wrapper
      @wrapper
    end

    def outgoing(type)
      @outgoing_rels[type.to_s] ||= OutgoingRels.new(self)
    end

    def save_nested(root_node)
      valid = true
      @outgoing_rels.each_pair do |type, rel|
        rel.each_with_index do |new_node, i|
        	wrapper = new_node.respond_to?(:wrapper) ? new_node.wrapper : new_node
          if wrapper.save
            new_rel = Neo4j::Relationship.new(type.to_sym, root_node, wrapper)
            rel.rels[i].props.each_pair { |property, value| new_rel[property] = value }
          else
            valid = false
          end
        end
      end
      valid
    end
    
    # this node doesn't exist in the DB yet
    def exist?
      false
    end

    class Relationship
    	include org.neo4j.graphdb.Relationship
      include Properties
      
      attr_reader :end_node, :start_node

      def initialize(from, to)
        @end_node = to
        @start_node = from
      end

      def wrapper
        self
      end

      def other_node(other)
        other == @end_node ? @start_node : @end_node
      end

      alias_method :getOtherNode, :other_node
    end


    class OutgoingRels
      include Enumerable
      attr_reader :rels

      def initialize(start_node)
        @rels = []
        @start_node = start_node
      end

      def <<(other)
        new(other)
        self
      end

      def new(other)
        new_rel = Relationship.new(@start_node, other)
        @rels << new_rel
        new_rel
      end

      def each
        @rels.each {|n| yield n.end_node}
      end

      def clear
        @rels.clear
      end

      def empty?
        @rels.empty?
      end

      def is_a?(type)
        # ActionView requires this for nested attributes to work
        return true if Array == type
        super
      end
    end

  end
end