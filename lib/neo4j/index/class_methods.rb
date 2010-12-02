module Neo4j
  module Index
    module ClassMethods
      attr_reader :_indexer

      extend Forwardable

      def wp_query(options, pager, args, &block) #:nodoc:
        params            = options[:params] || {}
        params[:page]     = pager.current_page
        params[:per_page] = pager.per_page
        res = [*find(options, params, &block)]
        pager.replace res
      end


      ##
      # See Neo4j::Index::Indexer#index
      # Forwards to the indexer that should be used.
      # It is possible to share the same index for several different classes, see #node_indexer.
      # :singleton-method: index

      ##
      # See Neo4j::Index::Indexer#find
      # Forwards to the indexer that should be used.
      # It is possible to share the same index for several different classes, see #node_indexer.
      # :singleton-method: find


      def_delegators :@_indexer, :index, :find, :index?, :index_type?, :delete_index_type, :rm_field_type, :add_index, :rm_index, :index_type_for, :index_name


      # Sets which indexer should be used for the given node class.
      # You can share an indexer between several different classes.
      #
      # ==== Example
      #   class Contact
      #      include Neo4j::NodeMixin
      #      index :name
      #      has_one :phone
      #   end
      #
      #   class Phone
      #      include Neo4j::NodeMixin
      #      property :phone
      #      node_indexer Contact  # put index on the Contact class instead
      #      index :phone
      #   end
      #
      #   # Find an contact with a phone number, this works since they share the same index
      #   Contact.find('phone: 12345').first #=> a phone object !
      #
      # ==== Returns
      # The indexer that should be used to index the given class
      def node_indexer(clazz)
        indexer(clazz, :node)
      end

      # Sets which indexer should be used for the given relationship class
      # Same as #node_indexer except that it indexes relationships instead of nodes.
      #
      def rel_indexer(clazz)
        indexer(clazz, :rel)
      end

      def indexer(clazz, type) #:nodoc:
        @_indexer = IndexerRegistry.create_for(self, clazz, type)
      end
    end
  end
end