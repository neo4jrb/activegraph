module Neo4j
  module Rails
    module Relationships

      # Holds the relationships in memory but also allows read access to persisted relationships
      class Storage #:nodoc:
        attr_reader :dsl, :node, :rel_type

        def initialize(node, rel_type, dsl=nil)
          @rel_type = rel_type.to_sym
          @node = node
          @rel_class = (dsl && dsl.relationship_class) || Neo4j::Rails::Relationship
          @target_class = (dsl && dsl.target_class) || Neo4j::Rails::Model
          @outgoing_rels = []
          @incoming_rels = []
          @persisted_related_nodes = {}
          @persisted_relationships = {}
          @persisted_node_to_relationships = {}
        end

        def to_s #:nodoc:
          "Storage #{object_id} node: #{@node.id} rel_type: #{@rel_type} outgoing #{@outgoing_rels.size}/#{@unpersisted_outgoing_rels && @unpersisted_outgoing_rels.size} incoming #{@incoming_rels.size}/#{@unpersisted_incoming_rels && @unpersisted_incoming_rels.size}"
        end

        def clear_unpersisted
          @outgoing_rels.clear
          @incoming_rels.clear
          @unpersisted_outgoing_rels = nil
          @unpersisted_incoming_rels = nil
        end

        def remove_from_identity_map
          @outgoing_rels.each {|r| Neo4j::IdentityMap.remove(r._java_rel)}
          @incoming_rels.each {|r| Neo4j::IdentityMap.remove(r._java_rel)}
          @unpersisted_outgoing_rels = nil
          @unpersisted_incoming_rels = nil
        end

        def count(dir)
          counter = 0
          # count persisted relationship
          @node._rels(dir, @rel_type).each { |*| counter += 1 } if @node.persisted?
          # count relationship which has not yet been persisted
          counter += relationships(dir).size
          counter
        end

        def to_other(dir, other)
          raise('node.rels(...).to_other() not allowed on a node that is not persisted') if @node.new_record?
          all_relationships(dir).find_all do |rel|
            rel._other_node(@node) == other
          end
        end

        def build(attrs)
          @target_class.new(attrs)
        end

        def create(attrs)
          @target_class.create(attrs)
        end

        def relationships(dir)
          case dir
            when :outgoing
              @unpersisted_outgoing_rels || @outgoing_rels
            when :incoming
              @unpersisted_incoming_rels || @incoming_rels
            when :both
              @incoming_rels + @outgoing_rels
          end
        end

        def each_rel(dir, &block) #:nodoc:
          relationships(dir).each { |rel| block.call rel }
          if @node.persisted?
            cache_relationships(dir) if @persisted_relationships[dir].nil?
            @persisted_relationships[dir].each {|rel| block.call rel unless !rel.exist?}
          end
        end

        def cache_relationships(dir)
          @persisted_relationships[dir] ||= []
          node._rels(dir, @rel_type).each do |rel|
            @persisted_relationships[dir] << rel.wrapper
          end
        end

        def cache_persisted_nodes_and_relationships(dir)
          @persisted_related_nodes[dir] ||= []
          @persisted_node_to_relationships[dir] ||= {}
          @node._rels(dir, @rel_type).each do |rel|
            end_node = rel._other_node(@node._java_node).wrapper
            @persisted_related_nodes[dir] << end_node
            @persisted_node_to_relationships[dir][end_node]=rel
          end
        end

        def relationship_deleted?(dir,node)
          @persisted_node_to_relationships[dir][node].nil? || !@persisted_node_to_relationships[dir][node].exist?
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
            cache_persisted_nodes_and_relationships(dir) if @persisted_related_nodes[dir].nil?
            @persisted_related_nodes[dir].each {|node| block.call node unless relationship_deleted?(dir,node)}
          end
        end

        def relationships?(dir)
          !!relationships(dir).first || (@node.persisted? && @node._rels(dir, @rel_type).first)
        end

        def single_relationship(dir, raw = false)
          rel = relationships(dir).first
          if rel.nil? && @node.persisted?
            java_rel = @node._rel(dir, @rel_type)
            raw ? java_rel : java_rel && java_rel.wrapper
          else
            rel
          end
        end

        def destroy_single_relationship(dir)
          rel = single_relationship(dir)
          rel && rel.destroy && relationships(dir).delete(rel)
        end

        def all_relationships(dir)
          Enumerator.new(self, :each_rel, dir)
        end

        def single_node(dir)
          rel = single_relationship(dir, true)
          rel && rel.other_node(@node)
        end

        def destroy_rels(dir, *nodes)
          all_relationships(dir).each do |rel|
            node = dir == :outgoing ? rel.end_node : rel.start_node
            dir == :incoming ? rm_incoming_rel(rel) : rm_outgoing_rel(rel)
            rel.destroy if nodes.include?(node)
          end
        end

        def create_relationship_to(to, dir, attributes=nil)
          if dir == :outgoing
            @rel_class.new(@rel_type, @node, to, attributes)
          else
            @rel_class.new(@rel_type, to, @node, attributes)
          end
        end

        def add_incoming_rel(rel)
          @incoming_rels << rel
        end

        def add_outgoing_rel(rel)
          @outgoing_rels << rel
        end

        # Makes the given relationship available in callbacks
        def add_unpersisted_incoming_rel(rel)
          @unpersisted_incoming_rels ||= []
          @unpersisted_incoming_rels << rel
        end

        # Makes the given relationship available in callbacks
        def add_unpersisted_outgoing_rel(rel)
          @unpersisted_outgoing_rels ||= []
          @unpersisted_outgoing_rels << rel
        end

        def rm_incoming_rel(rel)
          @incoming_rels.delete(rel)
        end

        def rm_outgoing_rel(rel)
          @outgoing_rels.delete(rel)
        end

        def rm_unpersisted_incoming_rel(rel)
          @unpersisted_incoming_rels.delete(rel)
          @unpersisted_incoming_rels = nil if @unpersisted_incoming_rels.empty?
        end

        def rm_unpersisted_outgoing_rel(rel)
          @unpersisted_outgoing_rels.delete(rel)
          @unpersisted_outgoing_rels = nil if @unpersisted_outgoing_rels.empty?
        end

        def persisted?
          @outgoing_rels.empty? && @incoming_rels.empty?
        end

        def persist
          out_rels = @outgoing_rels.clone
          in_rels = @incoming_rels.clone

          [@outgoing_rels, @incoming_rels, @persisted_related_nodes, @persisted_node_to_relationships, @persisted_relationships].each{|c| c.clear}

          out_rels.each do |rel|
            success = rel.persisted? || rel.save
            # don't think this can happen - just in case, TODO
            raise "Can't save outgoing #{rel}, validation errors ? #{rel.errors.inspect}" unless success
          end

          in_rels.each do |rel|
            success = rel.persisted? || rel.save
            # don't think this can happen - just in case, TODO
            raise "Can't save incoming #{rel}, validation errors ? #{rel.errors.inspect}" unless success
          end
        end
      end
    end
  end
end
