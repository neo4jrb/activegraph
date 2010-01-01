module Neo4j


  org.neo4j.impl.core.NodeProxy.class_eval do
    include Neo4j::JavaPropertyMixin
    include Neo4j::JavaRelationshipMixin
    include Neo4j::JavaListMixin

    # Deletes this node.
    # Deletes all relationships as well.
    # Invoking any methods on this node after delete() has returned is invalid and may lead to unspecified behavior.
    #
    # :api: public
    def del
      Neo4j.event_handler.node_deleted(wrapper) 

      # delete outgoing relationships, and check for cascade delete
      rels.outgoing.each { |r| r.del; r.end_node.del if r[:_cascade_delete_outgoing]}

      rels.incoming.each do |r|
        r.del
        if r[:_cascade_delete_incoming]
          node_id = r[:_cascade_delete_incoming]
          node = Neo4j.load_node(node_id)
          # check node has no outgoing relationships
          no_outgoing = node.rels.outgoing.empty?
          # check node has only incoming relationship with cascade_delete_incoming
          no_incoming = node.rels.incoming.find{|r| !node.ignore_incoming_cascade_delete?(r)}.nil?
          # only cascade delete incoming if no outgoing and no incoming (exception cascade_delete_incoming) relationships
          node.del if no_outgoing and no_incoming
        end
      end
      delete
      @_wrapper.class.indexer.delete_index(self) if @_wrapper
    end

    # --------------------------------------------------------------------------
    # Debug
    #

    def print(levels = 0, dir = :outgoing)
      print_sub(0, levels, dir)
    end

    def print_sub(level, max_level, dir)
      spaces = "  " * level
      node_class = (self[:_classname].nil?) ? Neo4j::Node.to_s : self[:_classname]
      node_desc = "#{spaces}neo_id=#{neo_id} #{node_class}"
      props.each_pair {|key, value| next if %w[id].include?(key) or key.match(/^_/) ; node_desc << " #{key}='#{value}'"}
      puts node_desc

      if (level != max_level)
        rels(dir).each do |rel|
          cascade_desc = ""
          cascade_desc << "cascade in: #{rel[:_cascade_delete_incoming]}" if rel.property?(:_cascade_delete_incoming)
          cascade_desc << "cascade out: #{rel[:_cascade_delete_outgoing]}" if rel.property?(:_cascade_delete_outgoing)
          puts "#{spaces}rel dir: #{dir} type: '#{rel.relationship_type}' neo_id: #{rel.neo_id} #{cascade_desc}"
          rel.other_node(self).print_sub(level + 1, max_level, dir)
        end
      end
    end

  end

  class Node
    class << self
      def new()
        node = Neo4j.create_node
        yield node if block_given?
        Neo4j.event_handler.node_created(node)
        node
      end
    end
  end

end
