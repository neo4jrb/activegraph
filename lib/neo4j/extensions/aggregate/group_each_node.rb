module Neo4j::Aggregate

  class GroupEachNode
    include Neo4j::NodeMixin
    include Enumerable

    has_one :aggregate
    property :aggregate_group, :aggregate_size, :group_by


    def each
      puts "each group #{group_by}"
      puts "Agg node #{aggregate.props.inspect}"
      group_by.split(',').each do |group|
        puts "VALUE key='#{group}' vakye=#{aggregate[group]}'"
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
    
  end

end