module Neo4j
  module Paginate
    def self.included(base)
      base.send(:include, WillPaginate::Finders::Base)
    end


    def wp_query(options, pager, args, &block) #:nodoc:
      page = pager.current_page || 1
      per_page = pager.per_page
      to = per_page * page
      from = to - per_page
      i = 0
      res = []
      each do |node|
        res << node.wrapper if i >= from
        i += 1
        break if i >= to
      end
      pager.replace res
      pager.total_entries ||= count
    end

  end
end