module Neo4j
  module Rails
    module Relationships

      class RelsDSL
        include Enumerable

        def initialize(from_node, mapper)
          @from_node = from_node
          @mapper    = mapper
          @direction = :both
        end

        def outgoing
          @direction = :outgoing
          self
        end

        def incoming
          @direction = :incoming
          self
        end
        
        def each(&block)
          @mapper.each_rel(@direction, &block)
        end

        def size
          to_a.size
        end

        def empty?
          size == 0
        end
      end

      class NodesDSL #:nodoc:
        include Enumerable

        def initialize(from_node, mapper, direction)
          @from_node = from_node
          @mapper    = mapper
          @direction = direction
        end

        def <<(other)
          puts "<< #{other} dir #{@direction} mapper: #{@mapper}"
          if @direction == :outgoing
            @mapper.create_relationship_to(@from_node, other, @direction)
          else
            @mapper.create_relationship_to(other, @from_node, @direction)
          end
          puts "added << #{other} mapper: #{@mapper}"

          self
        end

        def size
          @mapper.read_relationships(@direction).to_a.size
        end

        def each(&block)
          puts "NodesDSL @mapper=#{@mapper} dir #{@direction}"
          @mapper.each_node(@from_node, @direction, &block)
        end
      end

      def write_changed_relationships #:nodoc:
        @relationships.each_value do |mapper|
          mapper.persist
        end
      end

      def valid_relationships?(context, validated_nodes) #:nodoc:
        validated_nodes ||= Set.new
        !@relationships.values.find {|mapper| !mapper.valid?(context, validated_nodes)}
      end

      def _decl_rels_for(type) #:nodoc:
        dsl = super
        @relationships[type] ||= Mapper.new(type, dsl, self)
      end


      def clear_relationships #:nodoc:
        @relationships = {}
      end


      # If the node is persisted it returns a Neo4j::NodeTraverser
      # otherwise create a new object which will handle creating new relationships in memory.
      # If not persisted the traversal method like prune, expand, filter etc. will not be available
      #
      # See, Neo4j::NodeRelationship#outgoing (when node is persisted) which returns a Neo4j::NodeTraverser
      #
      def outgoing(rel_type)
        dsl = _decl_rels_for(rel_type)
        NodesDSL.new(self, dsl, :outgoing)
      end

      def incoming(rel_type)
        dsl = _decl_rels_for(rel_type)
        NodesDSL.new(self, dsl, :incoming)
      end

      def rels(*rel_types)
        if persisted?
          super
        else
          dsl = _decl_rels_for(rel_types.first.to_sym)
          RelsDSL.new(self, dsl)
        end
      end

      def add_outgoing_rel(rel_type, rel)
        dsl = _decl_rels_for(rel_type)
        dsl.add_outgoing_rel(rel)
      end
      
      def add_incoming_rel(rel_type, rel)
        puts "add_incoming_rel #{caller.inspect}"
        dsl = _decl_rels_for(rel_type)
        dsl.add_incoming_rel(rel)
      end
      
      def rm_incoming_rel(rel_type, rel)
        dsl = _decl_rels_for(rel_type)
        dsl.rm_incoming_rel(rel)
      end
    end
  end
end
