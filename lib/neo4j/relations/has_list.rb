module Neo4j

  module Relations
    class HasList
      include Enumerable
      extend Neo4j::TransactionalMixin

      def initialize(node, type, &filter)
        @node = node
        #@type = RelationshipType.instance(type)
        @type = type.to_s
      end

      def <<(other)
        Neo4j::Transaction.run do
          # does node have a relationship ?
          if (@node.relation?(@type))
            # get that relationship
            puts "relation exists"
            first = @node.relations.outgoing(@type).first
            puts "First #{first}"

            # delete this relationship
            first.delete
            old_first = first.other_node(@node)
            @node.add_relation(other, @type)
            other.add_relation(old_first, @type)
          else
            # the first node will be set
            @node.add_relation(other, @type)
          end
        end
      end

    end


  end

end