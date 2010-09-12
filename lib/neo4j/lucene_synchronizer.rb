module Neo4j
  class LuceneSynchronizer # :nodoc:
    include org.neo4j.graphdb.event.TransactionEventHandler

    def initialize
      @@fields ||= {}
    end

    def after_commit(data, state)
      #puts "before commit"
    end

    def after_rollback(data, state)
    end

    def find(lucene, field, query, props)
      key = index_key(field, props)
      lucene.get_nodes(key, query)
    end

    def index(field, props)
      # the key is just the field if the node we want to index is not using the class mapping (NodeMixin)
      # otherwise we use both the class and the field as a key
      #(props && props[:class]) ? "#{props[:class]}:#{field}" : field.to_s
      key = index_key(field, props)
      @@fields[key] = props || {}
    end

    def rm_index(lucene, field, props)
      key = index_key(field, props)
      lucene.remove_index(key)
      @@fields.delete(key)
    end

    # void afterCommit(TransactionData data, T state)
    def before_commit(data)
      data.assigned_node_properties.each { |tx_data| update_index(tx_data) if trigger_update?(tx_data) }
    end

    def index_key_for_node(field, node)
      return field unless node.property?(:_classname)
      # get root node
      clazz = Neo4j::Node.to_class(node[:_classname])
      "#{clazz.index_prefix}#{field}"
    end

    def index_key(field, props)
      props.nil? ? field.to_s : "#{props[:prefix]}#{field}"
    end


    def trigger_update?(tx_data)
      key = index_key_for_node(tx_data.key, tx_data.entity)
#      puts "trigger update #{tx_data.key} with key #{key} YES: #{@@fields[key].inspect} fields: #{@fields.inspect} id: #{self.object_id}"
      @@fields[key]
    end


    def update_index(tx_data)
      node = tx_data.entity
      key = index_key_for_node(tx_data.key, node)
#      puts "update index '#{key}' value:#{node[tx_data.key]}"

      # delete old index if it had a previous value
      node.rm_index(key) unless tx_data.previously_commited_value.nil?

      # add index
      node.index(key, node[tx_data.key])
    end
  end
end