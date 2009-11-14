module Neo4j::Aggregate

  class PropGroup
    include Neo4j::NodeMixin
    include Enumerable
#    alias :original_ignore_incoming_cascade_delete? :ignore_incoming_cascade_delete?

    has_one :aggregate, :cascade_delete => :incoming
    property :aggregate_group, :aggregate_size, :group_by

    def each
      group_by.split(',').each do |group|
        yield aggregate[group]
      end
    end

    # :api: private
    def get_property(key)
      value = super(key)
      return value unless value.nil?
      return nil unless aggregate
      aggregate[key]
    end

    def ignore_incoming_cascade_delete? (relationship)
      return true if super(relationship) #original_ignore_incoming_cascade_delete?(node,relationship)
      return true if relationship.start_node.kind_of?(Neo4j::Aggregate::PropsAggregate)
    end

  end

end