module Neo4j
  module Index
    class Indexer
      attr_reader :indexer_for, :field_types, :via_relationships, :entity_type, :parent_indexers, :via_relationships
      alias_method :index_types, :field_types  # public method accessible from node.index_types

      def initialize(clazz, type) #:nodoc:
        # part of the unique name of the index
        @indexer_for       = clazz

        # do we want to index nodes or relationships ?
        @entity_type              = type

        @indexes           = {} # key = type, value = java neo4j index
        @field_types       = {} # key = field, value = type (e.g. :exact or :fulltext)
        @via_relationships = {} # key = field, value = relationship

        # to enable subclass indexing to work properly, store a list of parent indexers and
        # whenever an operation is performed on this one, perform it on all
        @parent_indexers   = []
      end

      def inherit_fields_from(parent_index) #:nodoc:
        return unless parent_index
        @field_types.reverse_merge!(parent_index.field_types) if parent_index.respond_to?(:field_types)
        @via_relationships.reverse_merge!(parent_index.via_relationships) if parent_index.respond_to?(:via_relationships)
        @parent_indexers << parent_index
      end

      def to_s
        "Indexer @#{object_id} [index_for:#{@indexer_for}, field_types=#{@field_types.keys.join(', ')}, via=#{@via_relationships.inspect}]"
      end

      # Add an index on a field so that it will be automatically updated by neo4j transactional events.
      #
      # The index method takes an optional configuration hash which allows you to:
      #
      # === Add an index on an a property
      #
      # Example:
      #   class Person
      #     include Neo4j::NodeMixin
      #     index :name
      #   end
      #
      # When the property name is changed/deleted or the node created it will keep the lucene index in sync.
      # You can then perform a lucene query like this: Person.find('name: andreas')
      #'
      # === Add index on other nodes.
      #
      # Example:
      #
      #   class Person
      #     include Neo4j::NodeMixin
      #     has_n(:friends).to(Contact)
      #     has_n(:known_by).from(:friends)
      #     index :user_id, :via => :known_by
      #   end
      #
      # Notice that you *must* specify an incoming relationship with the via key, as shown above.
      # In the example above an index <tt>user_id</tt> will be added to all Person nodes which has a <tt>friends</tt> relationship
      # that person with that user_id. This allows you to do lucene queries on your friends properties.
      #
      # === Set the type value to index
      # By default all values will be indexed as Strings.
      # If you want for example to do a numerical range query you must tell Neo4j.rb to index it as a numeric value.
      # You do that with the key <tt>type</tt> on the property.
      #
      # Example:
      #   class Person
      #     include Neo4j::NodeMixin
      #     property :height, :weight, :type => Float
      #     index :height, :weight
      #   end
      #
      # Supported values for <tt>:type</tt> is <tt>String</tt>, <tt>Float</tt>, <tt>Date</tt>, <tt>DateTime</tt> and <tt>Fixnum</tt>
      #
      # === For more information
      # * See Neo4j::Index::LuceneQuery
      # * See #find
      #
      def index(*args)
        conf = args.last.kind_of?(Hash) ? args.pop : {}
        conf_no_via = conf.reject { |k,v| k == :via } # avoid endless recursion

        args.uniq.each do | field |
          if conf[:via]
            rel_dsl = @indexer_for._decl_rels[conf[:via]]
            raise "No relationship defined for '#{conf[:via]}'. Check class '#{@indexer_for}': index :#{field}, via=>:#{conf[:via]} <-- error. Define it with a has_one or has_n" unless rel_dsl
            raise "Only incoming relationship are possible to define index on. Check class '#{@indexer_for}': index :#{field}, via=>:#{conf[:via]}" unless rel_dsl.incoming?
            via_indexer               = rel_dsl.target_class._indexer

            field                     = field.to_s
            @via_relationships[field] = rel_dsl
            via_indexer.index(field, conf_no_via)
          else
            @field_types[field.to_s] = conf[:type] || :exact
          end
        end
      end

      def remove_index_on_fields(node, props, deleted_relationship_set) #:nodoc:
        @field_types.keys.each { |field| rm_index(node, field, props[field]) if props[field] }
        # remove all via indexed fields
        @via_relationships.each_value do |dsl|
          indexer = dsl.target_class._indexer
          deleted_relationship_set.relationships(node.getId).each do |rel|
            indexer.remove_index_on_fields(rel._start_node, props, deleted_relationship_set)
          end
        end
      end

      def update_on_deleted_relationship(relationship) #:nodoc:
        update_on_relationship(relationship, false)
      end

      def update_on_new_relationship(relationship) #:nodoc:
        update_on_relationship(relationship, true)
      end

      def update_on_relationship(relationship, is_created) #:nodoc:
        rel_type = relationship.rel_type
        end_node = relationship._end_node
        # find which via relationship match rel_type
        @via_relationships.each_pair do |field, dsl|
          # have we declared an index on this changed relationship ?
          next unless dsl.rel_type == rel_type

          # yes, so find the node and value we should update the index on
          val        = end_node[field]
          start_node = relationship._start_node

          # find the indexer to use
          indexer    = dsl.target_class._indexer

          # is the relationship created or deleted ?
          if is_created
            indexer.update_index_on(start_node, field, nil, val)
          else
            indexer.update_index_on(start_node, field, val, nil)
          end
        end
      end

      def update_index_on(node, field, old_val, new_val) #:nodoc:
        if @via_relationships.include?(field)
          dsl          = @via_relationships[field]
          target_class = dsl.target_class

          dsl._all_relationships(node).each do |rel|
            other = rel._start_node
            target_class._indexer.update_single_index_on(other, field, old_val, new_val)
          end
        end
        update_single_index_on(node, field, old_val, new_val)
      end

      def update_single_index_on(node, field, old_val, new_val) #:nodoc:
        if @field_types.has_key?(field)
          rm_index(node, field, old_val) if old_val
          add_index(node, field, new_val) if new_val
        end
      end

      # Returns true if there is an index on the given field.
      #
      def index?(field)
        @field_types.include?(field.to_s)
      end

      # Returns the type of index for the given field (e.g. :exact or :fulltext)
      #
      def index_type_for(field) #:nodoc:
        return nil unless index?(field)
        @field_types[field.to_s]
      end

      # Returns true if there is an index of the given type defined.
      def index_type?(type)
        @field_types.values.include?(type)
      end

      # Adds an index on the given entity
      # This is normally not needed since you can instead declare an index which will automatically keep
      # the lucene index in sync. See #index
      #
      def add_index(entity, field, value)
        return false unless @field_types.has_key?(field)
        conv_value = indexed_value_for(field, value)
        index = index_for_field(field.to_s)
        index.add(entity, field, conv_value)
        @parent_indexers.each { |i| i.add_index(entity, field, value) }
      end

      def indexed_value_for(field, value)
        # we might need to know what type the properties are when indexing and querying
        @decl_props ||= @indexer_for.respond_to?(:_decl_props) && @indexer_for._decl_props

        type        = @decl_props && @decl_props[field.to_sym] && @decl_props[field.to_sym][:type]
        return value unless type

        if String != type
          org.neo4j.index.lucene.ValueContext.new(value).indexNumeric
        else
          org.neo4j.index.lucene.ValueContext.new(value)
        end
      end

      # Removes an index on the given entity
      # This is normally not needed since you can instead declare an index which will automatically keep
      # the lucene index in sync. See #index
      #
      def rm_index(entity, field, value)
        return false unless @field_types.has_key?(field)
        index_for_field(field).remove(entity, field, value)
        @parent_indexers.each { |i| i.rm_index(entity, field, value) }
      end

      # Performs a Lucene Query.
      #
      # In order to use this you have to declare an index on the fields first, see #index.
      # Notice that you should close the lucene query after the query has been executed.
      # You can do that either by provide an block or calling the Neo4j::Index::LuceneQuery#close
      # method. When performing queries from Ruby on Rails you do not need this since it will be automatically closed
      # (by Rack).
      #
      # === Example, with a block
      #
      #   Person.find('name: kalle') {|query| puts "#{[*query].join(', )"}
      #
      # ==== Example
      #
      #   query = Person.find('name: kalle')
      #   puts "First item #{query.first}"
      #   query.close
      #
      # === Return Value
      # It will return a Neo4j::Index::LuceneQuery object
      #
      #
      def find(query, params = {})
        # we might need to know what type the properties are when indexing and querying
        @decl_props ||= @indexer_for.respond_to?(:_decl_props) && @indexer_for._decl_props

        index       = index_for_type(params[:type] || :exact)
        if query.is_a?(Hash) && (query.include?(:conditions) || query.include?(:sort))
          params.merge! query.except(:conditions)
          query.delete(:sort)
          query = query.delete(:conditions) if query.include?(:conditions)
        end
        query = (params[:wrapped].nil? || params[:wrapped]) ? LuceneQuery.new(index, @decl_props, query, params) : index.query(query)

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

      # delete the index, if no type is provided clear all types of indexes
      def delete_index_type(type=nil)
        if type
          #raise "can't clear index of type '#{type}' since it does not exist ([#{@field_types.values.join(',')}] exists)" unless index_type?(type)
          key = index_key(type)
          @indexes[key] && @indexes[key].delete
          @indexes[key] = nil
        else
          @indexes.each_value { |index| index.delete }
          @indexes.clear
        end
      end

      def on_neo4j_shutdown #:nodoc:
        # Since we might start the database again we must make sure that we don't keep any references to
        # an old lucene index in memory.
        @indexes.clear
      end

      # Removes the cached lucene index, can be useful for some RSpecs which needs to restart the Neo4j.
      #
      def rm_field_type(type=nil)
        if type
          @field_types.delete_if { |k, v| v == type }
        else
          @field_types.clear
        end
      end

      def index_for_field(field) #:nodoc:
        type           = @field_types[field]
        @indexes[index_key(type)] ||= create_index_with(type)
      end

      def index_for_type(type) #:nodoc:
        @indexes[index_key(type)] ||= create_index_with(type)
      end

      def index_key(type)
        index_names[type] + type.to_s
      end

      def lucene_config(type) #:nodoc:
        conf = Neo4j::Config[:lucene][type.to_sym]
        raise "unknown lucene type #{type}" unless conf
        conf
      end

      def create_index_with(type) #:nodoc:
        db           = Neo4j.started_db
        index_config = lucene_config(type)
        if @entity_type == :node
          db.lucene.for_nodes(index_names[type], index_config)
        else
          db.lucene.for_relationships(index_names[type], index_config)
        end
      end

      def index_names
        @index_names ||= Hash.new do |hash, index_type|
          default_filename = index_prefix + @indexer_for.to_s.gsub('::', '_')
          hash.fetch(index_type) {"#{default_filename}_#{index_type}"}
        end
      end

      protected
      def index_prefix
        return "" unless Neo4j.running?
        return "" unless @indexer_for.respond_to?(:ref_node_for_class)
        ref_node = @indexer_for.ref_node_for_class.wrapper
        prefix = ref_node.send(:_index_prefix) if ref_node.respond_to?(:_index_prefix)
        prefix ||= ref_node[:name] # To maintain backward compatiblity
        prefix.blank? ? "" : prefix + "_"
      end
    end
  end
end
