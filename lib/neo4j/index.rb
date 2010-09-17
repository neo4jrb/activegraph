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
        puts "add index #{@index_name} field #{field} type #{type}"
        @field_types[field.to_s] = type
        puts "fields #{@field_types.inspect}"
        # register with the event handler unless we haven't done this yet

        Neo4j.default_db.lucene.register(self) unless Neo4j.default_db.lucene.registered?(self)
      end

      def add_index(entity, field, value)
        index_for_field(field.to_s).add(entity, field, value)
      end

      def rm_index(entity, field, value)
        puts "remove entity #{entity}, #{field}, #{value}"
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
        db.lucene.provider.node_index("#{@index_name}-#{type}", index_config)
      end

      def trigger?(p_entry)
        # trigger if it's the right index and we have an index on the field that was changed
        node = p_entry.entity
        class_name = node.has_property('_classname') ? node.getProperty('_classname') : DEFAULT_INDEX_NAME
        class_name == @index_name && @field_types.include?(p_entry.key)
      end

      def trigger_remove?(p_entry)
        false
      end

      def update(p_entry)
        node = p_entry.entity
        rm_index(node, p_entry.key, p_entry.previously_commited_value) if p_entry.previously_commited_value

        # add index
        add_index(node, p_entry.key, p_entry.value)
      end

      def remove(p_entry)
        node = p_entry.entity
        puts "remove #{node.neo_id}"
        rm_index(node, p_entry.key, p_entry.previously_commited_value)
        puts "removed done"
      end

    end

  end

end