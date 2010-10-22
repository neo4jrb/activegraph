module Neo4j::Rails

  class Value
    include Neo4j::Property
    include org.neo4j.graphdb.Node

    def initialize(wrapper)
      @wrapper = wrapper
      @props = {}
      @outgoing_rels = {}  # a hash of all relationship with key type
    end

    # override Neo4j::Property#props
    def props
      @props
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

    # Pretend this object is a Java Node
    def has_property?(key)
      !@props[key].nil?
    end

    def set_property(key,value)
      @props[key] = value
    end

    def get_property(key)
      @props[key]
    end

    def remove_property(key)
      @props.delete(key)
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
        rel.each do |new_node|
          wrapper = new_node.respond_to?(:wrapper) ? new_node.wrapper : new_node
          if wrapper.save
            root_node.outgoing(type) << wrapper
          else
            valid = false
          end
        end
      end
      valid
    end

    class Relationship
      include org.neo4j.graphdb.Relationship
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