module Neo4j
  module Index
    module ClassMethods
      attr_reader :_indexer

      extend Forwardable

      def wp_query(options, pager, args, &block) #:nodoc:
        params            = {} 
        params[:page]     = pager.current_page
        params[:per_page] = pager.per_page
        query               = if args.empty?
                              find(options, params, &block)
                            else
                              args << params.merge(options)
                              find(*args, &block)
                            end

        pager.replace [*query]
        pager.total_entries = query.size
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

      ##
      # Specifies the location on the filesystem of the lucene index for the given index type.
      #
      # If not specified it will have the default location:
      #
      #   Neo4j.config[:storage_path]/index/lucene/node|relationship/ParentModuleName_SubModuleName_ClassName-indextype
      #
      # Forwards to the Indexer#index_names class
      #
      # ==== Example
      #  module Foo
      #    class Person
      #       include Neo4j::NodeMixin
      #       index :name
      #       index_names[:fulltext] = 'my_location'
      #    end
      #  end
      #
      #  Person.index_names[:fulltext] => 'my_location'
      #  Person.index_names[:exact] => 'Foo_Person-exact' # default Location
      #
      # The index can be prefixed, see Neo4j#threadlocal_ref_node= and multi dendency.
      #
      # :singleton-method: index_names


      ##
      # Returns a hash of which indexes has been defined and the type of index (:exact or :fulltext)
      #
      # :singleton-method: index_types


      def_delegators :@_indexer, :index, :find, :index?, :index_type?, :delete_index_type, :rm_field_type, :add_index, :rm_index, :index_type_for, :index_names, :index_types

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
        @_indexer ||= IndexerRegistry.create_for(self, clazz, type)
      end
    end
  end
end