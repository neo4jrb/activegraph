module Neo4j

  module Index

    # Adds an index on the given property
    # Notice that you normally don't have to do that since you simply can declare
    # that the property and index should be updated automatically by using the class method #index.
    #
    # The index operation will take place immediately unlike when using the Neo4j::Index::ClassMethods::index
    # method which instead will guarantee that the neo4j database and the lucene database will be consistent.
    # It uses a two phase commit when the transaction is about to be committed.
    #
    # ==== See also
    # Neo4j::Index::ClassMethods::index
    #
    def add_index(field, value=self[field])
      self.class.add_index(wrapped_entity, field.to_s, value)
    end

    # Removes an index on the given property.
    # Just like #add_index this is normally not needed since you instead can declare it with the
    # #index class method instead.
    #
    # ==== See also
    # Neo4j::Index::ClassMethods::index
    # Neo4j::Index#add_index
    #
    def rm_index(field, value=self[field])
      self.class.rm_index(wrapped_entity, field.to_s, value)
    end

    module ClassMethods
      attr_reader :_indexer

      extend Forwardable

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


      def_delegators :@_indexer, :index, :find, :index?, :index_type?, :clear_index_type, :rm_index_type, :add_index, :rm_index, :index_type_for, :index_name


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
      #      index :phone, :indexer => Person, :via => proc{|node| node.incoming(:phone).first}
      #   end
      #
      #   # Find an contact with a phone number, this works since they share the same index
      #   Contact.find('phone: 12345 AND name: 'pelle'')
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

      def indexer(clazz, type)  #:nodoc:
        @@indexers ||= {}
        if @@indexers.include?(clazz)
          # we want to reuse an existing index
          @_indexer = @@indexers[clazz]
          @_indexer.include_trigger(self)
        else
          @_indexer = Indexer.new(clazz, type)
          @@indexers[clazz] = @_indexer
        end
        @_indexer
      end
    end

    class WrappedQuery
      include Enumerable

      def initialize(index, query)
        @index = index
        @query = query
      end

      def each
        hits.each{|n| yield n.wrapper}
      end

      def close
        @hits.close if @hits
      end

      def empty?
        hits.size == 0
      end

      def size
        hits.size
      end

      def hits
        @hits ||= perform_query
      end

      def desc(*fields)
        @order = fields.inject(@order || {}){|memo, field| memo[field] = true; memo}
        self
      end

      def asc(*fields)
        @order = fields.inject(@order || {}){|memo, field| memo[field] = false; memo}
        self
      end

      def perform_query
        if @order
          java_sort_fields = @order.keys.inject([]) do |memo, field|
            memo << org.apache.lucene.search.SortField.new(field.to_s, org.apache.lucene.search.SortField::STRING, @order[field])
          end
          sort = org.apache.lucene.search.Sort.new(*java_sort_fields)
          @query = org.neo4j.index.impl.lucene.QueryContext.new(@query).sort(sort)
        end
        @index.query(@query)
      end
    end

    class Indexer
      attr_reader :index_name

      def initialize(clazz, type)
        @index_name = clazz.to_s

        # do we want to index nodes or relationships ?
        @type = type

        @indexes = {}  # key = type, value = java neo4j index
        @field_types = {}  # key = field, value = type (e.g. :exact or :fulltext)
        @triggered_by = [clazz.to_s]
        @via_entity = {}
      end

      def to_s
        "Indexer @#{object_id} [index_name:#{@index_name}, triggered_by=#{@triggered_by.join(', ')} fields=#{@field_types.keys.join(', ')} via=#{@via_entity.keys.join(', ')}]"
      end

      #  add an index on a field that will be automatically updated by events.
      def index(field, conf = {})
        if conf[:indexer]
          indexer = conf[:indexer]._indexer
          conf.delete :indexer
          indexer.index(field, conf)
          indexer.include_trigger @triggered_by[0]  # hmm ... TODO REFACTORING
        else
          type = conf[:type] || :exact
          @field_types[field.to_s] = type
          @via_entity[field.to_s] = conf[:via] if conf[:via]
          Neo4j.default_db.event_handler.add(self)
        end
      end

      def index?(field)
        @field_types.include?(field.to_s)
      end

      def index_type_for(field)
        return nil unless index?(field)
        @field_types[field.to_s]
      end

      def index_type?(type)
        @field_types.values.include?(type)
      end

      def add_index(entity, field, value)
        index_for_field(field.to_s).add(entity, field, value)
      end

      def rm_index(entity, field, value)
        index_for_field(field).remove(entity, field, value)
      end

      def find(query, params = {})
        type = params[:type] || :exact
        index = index_for_type(type)
        query = (params[:wrapped].nil? || params[:wrapped]) ? WrappedQuery.new(index, query) : index.query(query)

        if block_given?
          begin
            ret = yield query
          ensure
            query.close
          end
          ret
        else
          query
        end
      end

      # clears the index, if no type is provided clear all types of indexes
      def clear_index_type(type=nil)
        if type
          #raise "can't clear index of type '#{type}' since it does not exist ([#{@field_types.values.join(',')}] exists)" unless index_type?(type)
          @indexes[type] && @indexes[type].clear
        else
          @indexes.each_value{|index| index.clear}
        end
      end

      def rm_index_type(type=nil)
        if type
          #raise "can't remove index of type '#{type}' since it does not exist ([#{@field_types.values.join(',')}] exists)" unless index_type?(type)
          @field_types.delete_if {|k,v| v == type}
        else
          @field_types.clear
        end
      end

      def index_for_field(field)
        type = @field_types[field]
        @indexes[type] ||= create_index_with(type)
      end

      def index_for_type(type)
        @indexes[type] ||= create_index_with(type)
      end

      def lucene_config(type)
        conf = Neo4j::Config[:lucene][type.to_sym]
        raise "unknown lucene type #{type}" unless conf
        conf
      end

      def create_index_with(type)
        db=Neo4j.started_db
        index_config = lucene_config(type)
        if @type == :node
          db.lucene.node_index("#{@index_name}-#{type}", index_config)
        else
          db.lucene.relationship_index("#{@index_name}-#{type}", index_config)
        end
      end


      # ------------------------------------------------------------------
      # Event Handling

      def include_trigger(clazz)
         @triggered_by << clazz.to_s  unless @triggered_by.include?(clazz.to_s)
      end

      def trigger?(classname)
        @triggered_by.include?(classname || (@type==:node ? 'Neo4j::Node' : 'Neo4j::Relationship'))
      end

      def on_node_created(node)
        return unless trigger?(node['_classname'])
        @field_types.keys.each {|field| add_index(node, field, node[field]) if node.property?(field)}
      end

      def on_node_deleted(node, old_props)
        return unless trigger?(old_props['_classname'])
        @field_types.keys.each {|field| rm_index(node, field, old_props[field]) if old_props[field]}
      end

      def on_property_changed(node, field, old_val, new_val)
        return unless trigger?(node[:_classname]) && @field_types.include?(field)

        if @via_entity[field]
          # TODO refactoring
          node = @via_entity[field].call(node)
          node = node._java_node
        end
        rm_index(node, field, old_val) if old_val

        # add index
        add_index(node, field, new_val) if new_val
      end

      def on_rel_property_changed(rel, field, old_val, new_val)
        # works exactly like for nodes
        on_property_changed(rel, field, old_val, new_val)
      end

      def on_relationship_created(rel)
        # works exactly like for nodes
        on_node_created(rel)
      end

      def on_relationship_deleted(rel, old_props)
        # works exactly like for nodes
        on_node_deleted(rel, old_props)
      end

    end

  end

end