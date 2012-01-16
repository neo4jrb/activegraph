module Neo4j

  # The module implements the interface for pagination.
  # Currently relies on the fact that it's included into an Enumerable
  module Paginate
    extend ActiveSupport::Concern

    module InstanceMethods

      # Provides the pagination support on relations, queries etc.
      # TODO: Deprecate it in favour of external pagination gems.
      def paginate(options={})
        page = options[:page] || 1
        per_page = options[:per_page] || 30
        source = self
        Paginated.create_from source, page, per_page
      end

    end

  end


  # The class provides the pagination based on the given source.
  # The source must be an Enumerable implementing methods drop, first and count
  # This can be used to paginage any Enumerable collection and
  # provides the integration point for other gems, like will_paginate and kaminari.
  class Paginated
    include Enumerable
    attr_reader :items, :total_items, :current_page

    def initialize(items, total_items, current_page)
      @items, @total_items, @current_page = items, total_items, current_page
    end

    def self.create_from(source, page, per_page)
      items = source.drop((page-1) * per_page).first(per_page)
      Paginated.new(items, source.count, page)
    end

    def each
      @items.each { |x| yield x }
    end

    delegate :size, :[], :to => :items

    alias :total_entries :total_items

  end

end
