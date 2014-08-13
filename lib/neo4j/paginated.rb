module Neo4j
  class Paginated
    include Enumerable
    attr_reader :items, :total, :current_page

    def initialize(items, total, current_page)
      @items, @total, @current_page = items, total, current_page
    end

    def self.create_from(source, page, per_page)
      #partial = source.drop((page-1) * per_page).first(per_page)
      partial = source.skip(page-1).limit(per_page)
      Paginated.new(partial, source.count, page)
    end

    delegate :each, :to => :items
    delegate :size, :[], :to => :items
  end
end