module Neo4j

  class BatchItem < Struct.new(:neo_id, :inserter) # :nodoc:
    attr_accessor :_wrapper

    def []=(key, value)
      # not sure why I have to do it like this, Strange why I can't use the Java Hash ?
      # gets java.lang.UnsupportedOperationException: null, in java/util/AbstractMap.java:186:in `put'
      java_props = inserter.getNodeProperties(neo_id)
      ruby_props = {}
      java_props.keySet().each{|k| ruby_props[k] = java_props[k]}
      ruby_props[key.to_s] = value
      inserter.setNodeProperties(neo_id, ruby_props)
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
  #    c[:name] = "c"
  #    Neo4j::Relationship.new(:friend, a, b, :since => '2001-01-01')
  #    Neo4j::Relationship.new(:friend, Neo4j.ref_node, c, :since => '2001-01-01')
  #  end
  #
  # After the code block the normal creation for nodes and relationship will be used.
  # Traversals inside the batch inserter block is not possible.
  # The BatchInserter can be used together with Neo4j Migrations (see Neo4j#migration)
  #
  class BatchInserter

    #
    # See class description
    #
    def initialize(storage_path = Neo4j::Config[:storage_path])  # :yields: batch_inserter
      # Neo4j must not be running while using batch inserter, stop it just in case ...
      Neo4j::Transaction.finish
      Neo4j.stop

      # create the batch inserter
      inserter = org.neo4j.kernel.impl.batchinsert.BatchInserterImpl.new(storage_path)
      
      # save original methods
      create_node_meth = Neo4j.method(:create_node)
      create_rel_meth  = Neo4j.method(:create_rel)
      ref_node_meth    = Neo4j.method(:ref_node)
      
      # replace methods
      neo4j_meta = (class << Neo4j; self; end)
      neo4j_meta.instance_eval do
        define_method(:create_node) do |props|
          props ||= {}
          id = inserter.createNode(props.keys.inject({}) {|hash, key| hash[key.to_s] = props[key]; hash})
          BatchItem.new(id, inserter)
        end
        define_method(:create_rel) do |type, from_node, to_node, props|
          props.each_pair{|k, v| props.delete(k); props[k.to_s] = v} if props
          java_type = org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
          id = inserter.createRelationship(from_node.neo_id, to_node.neo_id, java_type, props)
          BatchItem.new(id, inserter)
        end
        define_method(:ref_node) do 
          BatchItem.new(inserter.getReferenceNode, inserter)
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
          define_method(:ref_node, ref_node_meth)
        end
      end
    end
  end


end



