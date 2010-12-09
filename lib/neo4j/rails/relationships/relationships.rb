module Neo4j
  module Rails
    module Relationships

      # TODO, reuse for incoming relationships ?
      class OutgoingRelationship #:nodoc:
        include Enumerable

        def initialize(from_node, mapper)
          @from_node = from_node
          @mapper    = mapper
        end

        def <<(other)
          @mapper.create_relationship_to(@from_node, other)
        end

        def each(&block)
          # TODO Direction
          @mapper.each &block
        end
      end

      
      def write_changed_relationships #:nodoc:
        @relationships.each_value do |mapper|
          mapper.persist
        end
      end

      def valid_relationships? #:nodoc:
        !@relationships.values.find {|mapper| !mapper.valid?}
      end

      def _decl_rels_for(type) #:nodoc:
        dsl = super
        if false && persisted?
          dsl
        else
          @relationships[type] ||= Mapper.new(type, dsl)
        end
      end


      def clear_relationships #:nodoc:
        @relationships = {}
      end


      # See, Neo4j::NodeRelationship#outgoing
      # Creates or traverse relationships in memory without communicating with the neo4j database.
      #
      def outgoing(rel_type)
        if persisted?
          super
        else
          @relationships[rel_type] ||= Mapper.new(rel_type)
          OutgoingRelationship.new(self, @relationships[rel_type])
        end
      end
    end
  end
end
