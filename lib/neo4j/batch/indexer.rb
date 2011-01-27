module Neo4j
  module Batch
    class Indexer

      delegate :field_types, :entity_type, :indexer_for, :indexed_value_for, :lucene_config, :via_relationships, :to => :@wrapped_indexer
      
      def initialize(wrapped_indexer)
        @wrapped_indexer = wrapped_indexer
        @parent_indexers = wrapped_indexer.parent_indexers.collect{|i| Indexer.new(i)}
      end

      def indexer_for_field(field)
        if via_relationships.include?(field)
          dsl          = via_relationships[field]
          target_class = dsl.target_class
          self.class.instance_for(target_class)
        else
          self
        end
      end

      def index_node(node, props) #:nodoc:
        return if props.empty?
        props_copy = props.clone

        while !props_copy.empty?
          indexer     = indexer_for_field(props_copy.keys.first)
          # put all other fields that are not of this index type in a new hash
          other_index = {}
          # delete all fields that are not of this index
          props_copy.delete_if { |k, v| indexer != indexer_for_field(k) && other_index[k] = v }
          # add all those properties for this index

          if indexer == self
            indexer.index_entity(node, props_copy)
          else
            # TODO THIS IS NOT NECCESSARLY - only do this when creating a relationship and check which relationship type it is
            self.class.inserter.rels(node).each do |rel|
              other = rel.start_node
              indexer.index_entity(other, props_copy)
            end
          end
          # continue with the remaining fields
          props_copy = other_index
        end
      end

      def index_entity(entity_id, props)
        filter_props = props.keys.inject({}) { |memo, field| memo[field] = indexed_value_for(field, props[field]) if field_types.has_key?(field); memo }
        return if filter_props.empty?

        while !filter_props.empty?
          # pick one index type
          index       = batch_index_for_field(filter_props.keys[0])
          # put all other fields that are not of this index type in a new hash
          other_index = {}
          # delete all fields that are not of this index
          filter_props.delete_if { |k, v| index != batch_index_for_field(k) && other_index[k] = v }
          # add all those properties for this index
          index.add(entity_id, filter_props)
          # continue with the remaining fields
          filter_props = other_index
        end

        @parent_indexers.each { |i| i.index_node(entity_id, props) }
      end

      def batch_index_for_field(field)
        type                 = field_types[field]
        @batch_indexes       ||= {}
        @batch_indexes[type] ||= create_batch_index_with(type)
      end

      def create_batch_index_with(type)
        index_config = lucene_config(type)

        if entity_type == :node
          self.class.index_provider.node_index("#{indexer_for}-#{type}", index_config)
        else
          self.class.index_provider.relationship_index("#{indexer_for}-#{type}", index_config)
        end
      end

      class << self
        attr_accessor :index_provider, :inserter

        def instance_for(clazz)
          @instances ||= {}
          @instances[clazz] ||= Indexer.new(clazz._indexer)
        end
      end
    end
  end
end
