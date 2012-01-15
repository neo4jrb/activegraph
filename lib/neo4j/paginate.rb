module Neo4j

  # The module implements the interface for pagination.
  # Currently relies on the fact that it's included into an Enumerable
    # TODO: Make it efficient, see https://github.com/andreasronge/neo4j/issues/130
  module Paginate
    extend ActiveSupport::Concern

    module InstanceMethods

      def paginate(options={})
        page = options[:page] || 1
        per_page = options[:per_page] || 30
        source = self
        Paginated.create_from source, page, per_page
      end

    end

    module ClassMethods

      def paginate(options={})
        page = options[:page] || 1
        per_page = options[:per_page] || 30

        finder_options = options.except(:page, :per_page)
        source = find(finder_options) # Requires a 'find' method with options
        Paginated.create_from source, page, per_page
      end

    end

  end


  class Paginated
    include Enumerable
    attr_reader :items, :total_items, :current_page

    def initialize(items, total_items, current_page)
      @items, @total_items, @current_page = items, total_items, current_page
    end

    def self.create_from(source, page, per_page)
      items = source.drop((page-1) * per_page).first(per_page)
      binding.pry
      Paginated.new(items, source.count, page)
    end

    def each
      @items.each { |x| yield x }
    end

    delegate :size, :[], :to => :items

    alias :total_entries :total_items

  end

end
