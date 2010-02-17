module Neo4j

  class BatchItem # :nodoc:
    attr_accessor :neo_id, :_wrapper

    def initialize(id, inserter)
      @neo_id = id
      @inserter = inserter
    end

    def []=(k, v)
      props = {}
      props[k.to_s] = v
      @inserter.setNodeProperties(self.neo_id, props)
    end
  end

  # Neo4j has a batch insert mode that drops support for transactions and concurrency in favor of insertion speed.
  # This is useful when you have a big dataset that needs to be loaded once. In our experience, the batch inserter will
  # typically inject data around five times faster than running in normal transactional mode.
  #
  # === Usage
  #
  # The initialize method takes a code block that will use the BatchInserter.
  #
  #  Neo4j::BatchInserter.new do |b|
  #    a = Neo4j::Node.new :name => 'a'
  #    b = Neo4j::Node.new :name => 'b'
  #    c = Foo.new :key1 => 'val1', :key2 => 'val2'
  #    Neo4j::Relationship.new(:friend, a, b, :since => '2001-01-01')
  #  end
  #
  # After the code block the normal creation for nodes and relationship will be used.
  # The BatchInserter can be used together with Neo4j Migrations (see Neo4j#migration)
  #
  class BatchInserter

    #
    # See class description
    #
    def initialize(storage_path = Neo4j::Config[:storage_path])  # :yields: batch_inserter
      inserter = org.neo4j.kernel.impl.batchinsert.BatchInserterImpl.new(storage_path)

      create_node_meth = Neo4j.method(:create_node)
      create_rel_meth = Neo4j.method(:create_rel)

      neo4j_meta = (
      class << Neo4j;
        self;
      end)
      neo4j_meta.instance_eval do
        define_method(:create_node) do |props|
          props ||= {}
          id = inserter.createNode(props.keys.inject({}) {|hash, key| hash[key.to_s] = props[key]; hash})
          BatchItem.new(id, inserter)
        end
      end

      neo4j_meta.instance_eval do
        define_method(:create_rel) do |type, from_node, to_node, props|
          props.each_pair{|k, v| props.delete(k); props[k.to_s] = v} if props
          java_type = org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
          id = inserter.createRelationship(from_node.neo_id, to_node.neo_id, java_type, props)
          BatchItem.new(id, inserter)
        end
      end

      begin
        yield inserter
      ensure
        inserter.shutdown
        # restore old methods
        neo4j_meta.instance_eval do
          define_method(:create_node, create_node_meth)
          define_method(:create_rel, create_rel_meth)
        end
      end
    end
  end


end



