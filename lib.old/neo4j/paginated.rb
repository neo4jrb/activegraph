module Neo4j

  # The class provides the pagination based on the given source.
  # The source must be an Enumerable implementing methods drop, first and count (or size).
  # This can be used to paginage any Enumerable collection and
  # provides the integration point for other gems, like will_paginate and kaminari.
  class Paginated
    include Enumerable
    attr_reader :items, :total, :current_page

    def initialize(items, total, current_page)
      @items, @total, @current_page = items, total, current_page
    end

    def self.create_from(source, page, per_page)
      partial = source.drop((page-1) * per_page).first(per_page)
      Paginated.new(partial, source.count, page)
    end

    delegate :each, :to => :items
    delegate :size, :[], :to => :items
  end
end
