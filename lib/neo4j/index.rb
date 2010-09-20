module Neo4j

  module Index
    def add_index(field, value=self[field])
      self.class.add_index(wrapped_entity, field.to_s, value)
    end

    def rm_index(field, value=self[field])
      self.class.rm_index(wrapped_entity, field.to_s, value)
    end

    module ClassMethods
      extend Forwardable

      def_delegators :@indexer, :index, :find, :index?, :index_type?, :clear_index_type, :rm_index_type, :add_index, :rm_index

      def indexer(clazz)
        @@indexers ||= {}
        if @@indexers.include?(clazz)
          # we want to reuse an existing index
          @indexer = @@indexers[clazz]
          @indexer.include_trigger(self)
        else
          @indexer = Indexer.new(clazz)
          @@indexers[clazz] = @indexer
        end
      end
    end

    class Indexer
      attr_reader :index_name

      def initialize(clazz)
        @@index_names ||= []
        @index_name = clazz.to_s
        raise "already created index for #{clazz}" if @@index_names.include?(@index_name)
        @@index_names << @index_name

        @indexes = {}  # key = type, value = java neo4j index
        @field_types = {}  # key = field, value = type (e.g. :exact or :fulltext)
        @triggered_by = clazz.to_s
      end

      #  add an index on a field that will be automatically updated by events.
      def index(field, conf = {})
        type = conf[:type] || :exact
        @field_types[field.to_s] = type
        Neo4j.default_db.event_handler.add(self)
      end

      def index?(field)
        @field_types.include?(field.to_s)
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

      def find(query, type = :exact)
        index = index_for_type(type)
        index.query(query)
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
        db.lucene.node_index("#{@index_name}-#{type}", index_config)
      end


      # ------------------------------------------------------------------
      # Event Handling

      def include_trigger(clazz)
         @triggered_by << clazz.to_s  unless @triggered_by.include?(clazz.to_s)
      end

      def trigger?(classname)
        @triggered_by.include?(classname || 'Neo4j::Node')
      end

      def on_node_created(node)
        return unless trigger?(node['_classname'])
        @field_types.keys.each {|field| add_index(node, field, node[field]) if node.property?(field)}
      end

      def on_node_deleted(node, old_props)
        return unless @triggered_by.include?(old_props['_classname'] || 'Neo4j::Node')
        @field_types.keys.each {|field| rm_index(node, field, old_props[field]) if old_props[field]}
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