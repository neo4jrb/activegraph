module Neo4j

  module Index
    def add_index(field, value=self[field], indexer = self.class.indexer)
      indexer.add_index(wrapped_entity, field.to_s, value)
    end

    def rm_index(field, value=self[field], indexer = self.class.indexer)
      indexer.rm_index(wrapped_entity, field.to_s, value)
    end

    module ClassMethods
      def indexer=(indexer)
        @indexer = indexer
      end

      def indexer
        @indexer ||= Indexer.new(Neo4j::Node)
      end

      def index(field, conf = {})
        indexer.index(field, conf[:type] || :exact)
      end

      def find(query, type = :exact)
        indexer.find(query, type)
      end

      # clear the index of given type. if type == nil then clear all types of indexes
      def clear_index(type = nil)
        indexer.clear(type)
      end

      def unregister_index(type = nil)
        indexer.unregister_index(type)
      end
    end

    class Indexer
      DEFAULT_INDEX_NAME = 'Neo4j::Node'  # if a node does not have a _classname property use this index
      attr_reader :index_name

      def initialize(clazz)
        @@index_names ||= []
        @index_name = clazz.to_s
        raise "already created index for #{clazz}" if @@index_names.include?(@index_name)
        @@index_names << @index_name

        @indexes = {}  # key = type, value = java neo4j index
        @field_types = {}  # key = field, value = type (e.g. :exact or :fulltext)
      end

      #  add an index on a field that will be automatically updated by events.
      def index(field, type)
        @field_types[field.to_s] = type
        Neo4j.default_db.event_handler.add(self)
      end

      def add_index(entity, field, value)
        index_for_field(field.to_s).add(entity, field, value)
      end

      def rm_index(entity, field, value)
        index_for_field(field).remove(entity, field, value)
      end

      def find(query, type)
        index = index_for_type(type)
        raise "no index #{@index_name} of type #{type} defined ('#{@indexes.inspect}')" if index.nil?
        index.query(query)
      end

      # clears the index, if no type is provided clear all types of indexes
      def clear(type)
        if type
          index_for_type(type).clear
        else
          @indexes.each_value{|index| index.clear}
        end
      end

      def unregister_index(type)
        if type
          @indexes.delete type
        else
          @field_types.delete_if {|k,v| v == type}
          @indexes.each_value{|index| index.clear}
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
        # TODO by some weired reason we can't but this in a hash
        case type.to_sym
          when :exact then org.neo4j.index.impl.lucene.LuceneIndexProvider::EXACT_CONFIG
          when :fulltext then org.neo4j.index.impl.lucene.LuceneIndexProvider::FULLTEXT_CONFIG
          else raise "unknown lucene type #{type}"
        end
      end

      def create_index_with(type)
        db=Neo4j.started_db
        index_config = lucene_config(type) #LUCENE_CONFIG[type.to_sym] # Neo4j::Config[:lucene][type.to_sym]
        raise "no lucene configuration of type '#{type}' available" if index_config.nil?
        db.lucene.node_index("#{@index_name}-#{type}", index_config)
      end


      # ------------------------------------------------------------------
      # Event Handling

      def trigger?(classname)
        @index_name == classname || (classname.nil? && @index_name == 'Neo4j::Node')
      end

      def on_node_created(node)
        return unless trigger?(node['_classname'])
        @field_types.keys.each {|field| add_index(node, field, node[field])}
      end

      def on_node_deleted(node, old_props)
        return unless trigger?(old_props['_classname'])
        @field_types.keys.each {|field| rm_index(node, field, old_props[field])}
      end

      def on_property_changed(node, field, old_val, new_val)
        return unless trigger?(node[:_classname]) && @field_types.include?(field)

        rm_index(node, field, old_val) if old_val

        # add index
        add_index(node, field, new_val) if new_val
      end
    end

  end

end