module Neo4j
  class Paginated
    include Enumerable
    attr_reader :items, :total, :current_page

    def initialize(items, total, current_page)
      @items = items
      @total = total
      @current_page = current_page
    end

    def self.create_from(source, page, per_page, order = nil)
      target = source.node_var || source.identity
      partial = source.skip((page - 1) * per_page).limit(per_page)
      ordered_partial, ordered_source = if order
                                          [partial.order_by(order), source.query.with("#{target} as #{target}").pluck("COUNT(#{target})").first]
                                        else
                                          [partial, source.count]
                                        end
      Paginated.new(ordered_partial, ordered_source, page)
    end

    delegate :each, to: :items
    delegate :pluck, to: :items
    delegate :size, :[], to: :items
  end
end
