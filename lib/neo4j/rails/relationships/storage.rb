module Neo4j
  module Rails
    module Relationships

      # Holds the relationships in memory but also allows read access to persisted relationships
      class Storage #:nodoc:
        include Neo4j::ToJava
        attr_reader :dsl, :node, :rel_type

        def initialize(node, rel_type, rel_class)
          @rel_type      = rel_type.to_sym
          @node          = node
          @rel_class     = rel_class || Neo4j::Rails::Relationship
          @outgoing_rels = []
          @incoming_rels = []
        end

        def to_s #:nodoc:
          "#{self.class} #{object_id} rel_type: #{@rel_type} outgoing #{@outgoing_rels.size} incoming #{@incoming_rels.size}"
        end

        def modified?
          !(@outgoing_rels.empty? && @incoming_rels.empty?)
        end


        def size(dir)
          counter = 0
          # count persisted relationship
          @node._java_node && @node._java_node.getRelationships(java_rel_type, dir_to_java(dir)).each {|*| counter += 1 }
          # count relationship which has not yet been persisted
          counter += relationships(dir).size
          counter
        end

        def relationships(dir)
          case dir
            when :outgoing
              @outgoing_rels
            when :incoming
              @incoming_rels
            when :both
              @incoming_rels + @outgoing_rels
          end
        end

        def java_rel_type
          type_to_java(rel_type)
        end

        def each_rel(dir, &block) #:nodoc:
          relationships(dir).each { |rel| block.call rel }

          if @node.persisted?
            node._java_node.getRelationships(java_rel_type, dir_to_java(dir)).each do |rel|
              block.call rel.wrapper
            end
          end
        end

        def each_node(dir, &block)
          relationships(dir).each do |rel|
            if rel.start_node == @node
              block.call rel.end_node
            else
              block.call rel.start_node
            end
          end

          if @node.persisted?
            @node._java_node.getRelationships(java_rel_type, dir_to_java(dir)).each do |rel|
              block.call rel.getOtherNode(@node._java_node).wrapper
            end
          end
        end

        def single_relationship(dir)
          rel = relationships(dir).first
          if rel.nil? && @node.persisted?
            rel = @node._java_node.getSingleRelationship(java_rel_type, dir_to_java(dir))
            # TODO wrapper
          end

          rel
        end

        def all_relationships(dir)
          Enumerator.new(self, :each_rel, dir)
        end

        def single_node(dir)
          rel = single_relationship(dir)
          puts "REL = #{rel}"
          rel && rel.get_other_node(@node).wrapper  # TODO wrapper
        end

        def del_rel(rel)
          if relationships.delete(rel)
            if direction == :outgoing
              rel.end_node.del_rel
            else
              rel.start_node.del_rel
            end
          end
        end

        def create_relationship_to(to, dir)
          if dir == :outgoing
            rel = @rel_class.new(@rel_type, @node, to, self)
            to.class != Neo4j::Node && to.add_incoming_rel(@rel_type, rel)
            add_outgoing_rel(rel)
          else
            rel = @rel_class.new(@rel_type, to, @node, self)
            @node.class != Neo4j::Node && to.add_outgoing_rel(@rel_type, rel)
            add_incoming_rel(rel)
          end
        end
        
        def add_incoming_rel(rel)
          @incoming_rels << rel
        end

        def add_outgoing_rel(rel)
          puts "ADD OUTGOING for #{@node} #{rel}"
          @outgoing_rels << rel
        end

        def rm_incoming_rel(rel)
          @incoming_rels.delete(rel)
        end
        
        def valid?(context, validated_nodes)
          return true if validated_nodes.include?(@node)
          all_valid = true

          !@outgoing_rels.each do |rel|
            start_node = rel.start_node
            end_node = rel.end_node
            #start_node, end_node = end_node, start_node if @node == end_node

            validated_nodes << start_node << end_node
            if !end_node.valid?(context, validated_nodes)
              all_valid                = false
              start_node.errors[@rel_type.to_sym] ||= []
              start_node.errors[@rel_type.to_sym] << end_node.errors.clone
            elsif !start_node.valid?(context, validated_nodes)
              all_valid                = false
              end_node.errors[@rel_type.to_sym] ||= []
              end_node.errors[@rel_type.to_sym] << start_node.errors.clone
            end
          end
          all_valid
        end

        def persist
          puts "PERSIST #{@node} outgoing: #{@outgoing_rels.inspect}, @incoming_rels=#{@incoming_rels.inspect}"
          success = true
          @outgoing_rels.each do |rel|
            success = rel.save
            puts " ERROR #{rel.errors.inspect}" unless success
            break unless success
          end

          puts "  success = #{success}"

          if success
            @outgoing_rels.each do |rel|
              rel.end_node.rm_incoming_rel(@rel_type.to_sym, rel)
            end
            @outgoing_rels.clear

            @incoming_rels.each do |rel|
              puts "  persist incoming #{rel}"
              success = rel.start_node.persisted? || rel.start_node.save
              puts " ERROR #{rel.errors.inspect}" unless success
              break unless success
            end
            success
          end

          puts "  ret #{success}"
          success
        end
      end
    end
  end
end
