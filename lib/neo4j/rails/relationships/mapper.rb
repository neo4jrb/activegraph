module Neo4j
  module Rails
    module Relationships

      class Mapper #:nodoc:
        attr_reader :dsl

        def initialize(rel_type, dsl, node)
          @rel_type      = rel_type
          @relationships = []
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
          "#{self.class} #{object_id} dir: #{direction} rel_type: #{@rel_type} wrapped #{@dsl}"
        end
        
        def single_relationship(*)
          use_persisted_rels? ? @dsl.single_relationship(@node) : @relationships.first
        end

        def all_relationships(*)
          if use_persisted_rels?
            @dsl.all_relationships(@node)
          else
            @relationships
          end
        end

        def each_node(node, direction, &block)
          if use_persisted_rels?
            @dsl.each_node(node, direction, &block)
          else
            # TODO direction
            @relationships.each do |rel|
              block.call rel.end_node
            end
          end
        end

        def use_persisted_rels?
          @relationships.empty? && @node.persisted?
        end

        def del_rel(rel)
          @relationships.delete(rel)
        end

        def create_relationship_to(from, to)
          @relationships << Relationship.new(@rel_type, from, to, self)
        end
        

        def single_node(from)
          if !@relationships.empty?
            @relationships.first.end_node
          else
            @dsl.single_node(from) if @dsl && from.persisted?
          end
        end

        def valid?
          all_valid = true
          !@relationships.each do |rel|
            start_node = rel.start_node
            end_node = rel.end_node

            if !end_node.valid?
              all_valid                = false
              start_node.errors[@rel_type.to_sym] ||= []
              start_node.errors[@rel_type.to_sym] << end_node.errors
            end
          end
          all_valid
        end

        def persist
          @relationships.each do |rel|
            if @dsl
              start_node = rel.start_node
              end_node = rel.end_node

              end_node.save!
              @dsl.create_relationship_to(start_node, end_node)
            else
              rel.end_node.save!
              rel.start_node.outgoing(@rel_type) << rel.end_node
            end
          end
        end
      end
    end
  end
end
