module Neo4j
  module Index
    class Indexer
      attr_reader :indexer_for

      def initialize(clazz, type)
        # part of the unique name of the index
        @indexer_for = clazz

        # do we want to index nodes or relationships ?
        @type = type

        @indexes = {} # key = type, value = java neo4j index
        @field_types = {} # key = field, value = type (e.g. :exact or :fulltext)
        @via_relationships = {} # key = field, value = relationship
      end

      def to_s
        "Indexer @#{object_id} [index_for:#{@indexer_for}, field_types=#{@field_types.keys.join(', ')}, via=#{@via_relationships.inspect}]"
      end

      #  add an index on a field that will be automatically updated by events.
      def index(field, conf = {})
        if conf[:via]
          rel_dsl = @indexer_for._decl_rels[conf[:via]]
          via_indexer = rel_dsl.to_class._indexer
          raise "No relationship defined for '#{conf[:via]}'. Check class '#{@indexer_for}': index #{field}, via=#{conf[:via]} <-- error. Define it with a has_one or has_n" unless rel_dsl
          field = field.to_s
          @via_relationships[field] = rel_dsl
          conf.delete :via # avoid endless recursion
          via_indexer.index(field, conf)
        else
          @field_types[field.to_s] = conf[:type] || :exact
        end
      end

      def add_index_on_all_fields(node)
        @field_types.keys.each { |field| add_index(node, field, node[field]) if node.property?(field) }
      end

      def remove_index_on_fields(node, props, tx_data)
        @field_types.keys.each { |field| rm_index(node, field, props[field]) if props[field] }
        # for each via relationship delete it
        @via_relationships.each_pair do |field, dsl|
          rel_type = dsl.incoming_dsl.namespace_type
          to_class = dsl.to_class

          tx_data.deleted_relationships.each do |rel|
            other = rel._start_node
            to_class._indexer.remove_index_on_fields(other, props, tx_data)
          end

          node.rels(rel_type).incoming.each do |rel|
            other = rel._start_node
            to_class._indexer.remove_index_on_fields(other, props)
          end
        end
      end

      def update_index_on(node, field, old_val, new_val)
        if @via_relationships.include?(field)
          dsl = @via_relationships[field]
          rel_type = dsl.incoming_dsl.namespace_type
          to_class = dsl.to_class
          node.rels(rel_type).incoming.each do |rel|
            other = rel._start_node
            to_class._indexer.update_index_on(other, field, old_val, new_val)
          end

        elsif @field_types.include?(field)
          rm_index(node, field, old_val) if old_val

          # add index
          add_index(node, field, new_val) if new_val
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
          @indexes.each_value { |index| index.clear }
        end
      end

      def rm_index_type(type=nil)
        if type
          #raise "can't remove index of type '#{type}' since it does not exist ([#{@field_types.values.join(',')}] exists)" unless index_type?(type)
          @field_types.delete_if { |k, v| v == type }
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
          db.lucene.node_index("#{@indexer_for}-#{type}", index_config)
        else
          db.lucene.relationship_index("#{@indexer_for}-#{type}", index_config)
        end
      end

    end

  end

end