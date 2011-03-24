module Neo4j
  module Rails
    module Relationships

      class Mapper #:nodoc:
        include Neo4j::ToJava
        attr_reader :dsl

        def initialize(rel_type, dsl, node)
          @rel_type      = rel_type
          @outgoing_rels = []
          @incoming_rels = []
          @dsl           = dsl
          @node          = node
        end

        def rel_type
          (@dsl && @dsl.rel_type) || @rel_type
        end

        def direction
          (@dsl && @dsl.direction) || :outgoing
        end

        def to_s #:nodoc:
          "#{self.class} #{object_id} dir: #{direction} rel_type: #{@rel_type} wrapped #{@dsl} outgoing #{@outgoing_rels.size} incoming #{@incoming_rels.size}"
        end

        def read_relationships(dir = direction) #, persisted = use_persisted_rels?)
          Enumerator.new(self, :each_rel, dir)
        end

        def write_relationships(dir = direction)
          dir == :outgoing ? @outgoing_rels : @incoming_rels
        end

        def single_relationship(*)
          use_persisted_rels? ? @dsl.single_relationship(@node) : read_relationships.first
        end

        def all_relationships(*)
          read_relationships
        end

        def each_rel(direction, &block)
          if @node._java_node
            if @dsl
              @dsl.each_rel(@node, direction, &block)
            else
              @node._java_node.getRelationships(type_to_java(@rel_type), dir_to_java(direction)).each { |rel| block.call rel.wrapper }
            end
          end
          write_relationships(direction).each do |rel|
            block.call rel
          end
        end

        def each_node(node, direction, &block)
          if @node._java_node
            if @dsl
              @dsl.each_node(@node, direction, &block)
            else
              @node._java_node.getRelationships(type_to_java(@rel_type), dir_to_java(direction)).each { |rel| block.call rel.getOtherNode(@node._java_node).wrapper }
            end
          end
          write_relationships(direction).each do |rel|
            if direction == :outgoing
              block.call rel.end_node
            else
              block.call rel.start_node
            end
          end
        end


        def use_persisted_rels?
          @outgoing_rels.empty? && @incoming_rels.empty? && @node.persisted?
        end

        def del_rel(rel)
          if write_relationships.delete(rel)
            if direction == :outgoing
              rel.end_node.del_rel
            else
              rel.start_node.del_rel
            end
          end
        end

        def rel_type_with_prefix
          @dsl && @dsl.rel_type || @rel_type
        end
        
        def create_relationship_to(from, to, dir = direction)
          clazz = (@dsl && @dsl.relationship_class) || Neo4j::Rails::Relationship
          rel = clazz.new(rel_type_with_prefix, from, to, self)
          write_relationships(direction) << rel #Relationship.new(@rel_type, from, to, self)
          if dir == :outgoing
            puts "add_incoming_rel #{rel}"
            to.add_incoming_rel(@rel_type, rel)
          else
            puts "add_outgoing_rel #{rel}"
            from.add_outgoing_rel(@rel_type, rel)
          end

          puts "exit create_relationship_to #{from} #{to}, size = #{write_relationships(direction).size}"
        end
        
        def add_incoming_rel(rel)
          puts "-- add_incoming_rel on #{@node} #{@node.id}"
          @incoming_rels << rel
        end

        def add_outgoing_rel(rel)
          puts "-- add_outgoing_rel on #{@node} #{@node.id}"
          @outgoing_rels << rel
        end

        def rm_incoming_rel(rel)
          @incoming_rels.delete(rel)
        end
        
        def single_node(*)
          first = read_relationships.first
          first && first.end_node
        end

        def valid?(context, validated_nodes)
          return true if validated_nodes.include?(@node)
          all_valid = true

          !@outgoing_rels.each do |rel|
            start_node = rel.start_node
            end_node = rel.end_node
            #start_node, end_node = end_node, start_node if @node == end_node

            # TODO
            included_end_node = validated_nodes.include?(end_node)
            included_start_node = validated_nodes.include?(start_node)
            validated_nodes << start_node << end_node
            if end_node_valid = !end_node.valid?(context, validated_nodes)
              all_valid                = false
              start_node.errors[@rel_type.to_sym] ||= []
              start_node.errors[@rel_type.to_sym] << end_node.errors.clone
            end
            if start_node_valid = !start_node.valid?(context, validated_nodes)
              all_valid                = false
              end_node.errors[@rel_type.to_sym] ||= []
              end_node.errors[@rel_type.to_sym] << start_node.errors.clone
            end
          end
          all_valid
        end

        def persist
          success = true
          @outgoing_rels.each do |rel|
            success = rel.save
            break unless success
          end

          if success
            @outgoing_rels.each do |rel|
              rel.end_node.rm_incoming_rel(@rel_type.to_sym, rel)
            end
            @outgoing_rels.clear

            @incoming_rels.each do |rel|
              success = rel.end_node.persisted? || rel.end_node.save
              break unless success
            end
            success
          end

          puts "persisted #{success}"
          success

#            if @dsl
#              start_node = rel.start_node
#              end_node = rel.end_node
#
#              end_node.save!
#              @dsl.create_relationship_to(start_node, end_node)
#            else
#              rel.end_node.save!
#              rel.start_node.outgoing(@rel_type) << rel.end_node
#            end
#          end
        end
      end
    end
  end
end
