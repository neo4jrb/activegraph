module Neo4j

  module Relations
    class HasList
      include Enumerable
      extend Neo4j::TransactionalMixin

      def initialize(node, type, &filter)
        @node = node
        @type = RelationshipType.instance(type)
        @traverser = NodeTraverser.new(node.internal_node)
        @info = node.class.relations_info[type.to_sym]
        @traverser.filter(&filter) unless filter.nil?
      end

      def <<(other)
        # does node have a relationship ?
        r = @node.internal_node.createRelationshipTo(to.internal_node, @type)
        @node.class.new_relation(@type.name,r)

        from.class.indexer.on_relation_created(from, @type.name)
        self
      end

    end


  end

end