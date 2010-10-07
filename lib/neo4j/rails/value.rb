module Neo4j

  class Value
    include Neo4j::Property
    include org.neo4j.graphdb.Node

    def initialize(*args)
      # the first argument can be an hash of properties to set
      @props = {}
      if args[0].respond_to?(:each_pair)
        args[0].each_pair { |k, v| set_property(k.to_s, v) }
      end
      @rels = {}  # a hash of all relationship with key type
    end

    # override Neo4j::Property#props
    def props
      @props
    end

    def getId
      nil
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

    def outgoing(type)
      @rels[type.to_sym] ||= OutgoingRels.new
    end

    def save_nested(root_node)
      valid = true
      @rels.each_pair do |type, rel|
        rel.each do |new_node|
          if new_node.save
            root_node.outgoing(type) << new_node
          else
            valid = false
          end
        end
      end
      valid
    end

    class OutgoingRels
      include Enumerable
      def initialize
        @nodes = []
      end

      def <<(other)
        @nodes << other
      end

      def each
        @nodes.each {|n| yield n}
      end

      def empty?
        @nodes.empty?
      end

      def is_a?(type)
        # ActionView requires this for nested attributes to work
        return true if Array == type
        super
      end
    end

  end
end