module Neo4j

  # This class is responsible for both knowing which nodes that needs to be reindexed
  # and how to perform the reindex operation.
  # 
  # There is one Indexer per Node root class.
  #
  class Indexer
    attr_reader :document_updaters
    
    def initialize(clazz)
      @relation_indexers = {}
      @property_indexer = PropertyIndexer.new
      @document_updaters = [@property_indexer]
      # the file name of the lucene index if kept on disk
      @index_path = clazz.root_class.gsub('::', '/')
    end
    
    def self.instance(clazz)
      @instances ||= {}
      @instances[clazz.root_class] ||= Indexer.new(clazz)
      @instances[clazz.root_class]
    end

    # only for testing purpose
    def self.clear_all_instances
      @instance == nil
    end
    
    def self.index(node)
      indexer = instance(node.class)
      indexer.index(node)
    end
    
    def add_index_on_property(prop)
      @property_indexer.properties << prop
    end

    def remove_index_on_property(prop)
      @property_indexer.properties.delete prop
    end

    def add_index_in_relation_on_property(target_class, rel_name, rel_type, prop)
      if relation_indexer_for?(rel_name)
        indexer = new_relation_indexer_for(rel_name, rel_type)
        self.instance(target_class).document_updaters << indexer
      end
      relation_indexer_for(rel_name).properties << prop
    end

    def index(node)
      document = {:id => node.neo_node_id }

      @document_updaters.each do |updater|
        updater.update_document(document, node)
      end

      lucene_index << document
    end

    def lucene_index
      Lucene::Index.new(@index_path)
    end
    
    def on_property_changed(node, prop)
      # which triggers will be triggered when the property is changed ?
      trigger_update_index(node, find_indexers_for_property(prop))
    end

    def on_relation_created_or_deleted(to_node, rel_type)
      trigger_update_index(to_node, find_indexers_for_relation(rel_type))
    end

    def find_indexers_for_property(prop)
      all = @relation_indexers.values.find_all { |indexer| indexer.on_property_changed?(prop) }
      all << @property_indexer if @property_indexer.on_property_changed?(prop)
      all
    end

    def find_indexers_for_relation(rel_type)
      @relation_indexers.values.find_all { |indexer| indexer.on_relation_created_or_deleted?(rel_type) }
    end

    # for all the given triggers find all the nodes that they think needs to be reindexed
    def trigger_update_index(node, indexers)
      indexers.each do |indexer|
        # notice that a trigger on one node may trigger updates on several other nodes
        indexer.nodes_to_be_reindexed(node).each do |related_node|
          Indexer.index(related_node)
        end
      end
    end

    def relation_indexer_for(rel_name)
      @relation_indexers[rel_name]
    end

    def relation_indexer_for?(rel_name)
      !relation_indexer_for(rel_name).nil?
    end

    def new_relation_indexer_for(rel_name, rel_type)
      @relation_indexers[rel_name] = RelationIndexer.new(rel_name, rel_type)
    end

  end

  
  class PropertyIndexer
    attr_reader :properties

    def initialize
      @properties = []
    end

    def nodes_to_be_reindexed(node)
      [node]
    end
    
    def on_property_changed?(prop)
      @properties.include?(prop)
    end

    def update_document(document, node)
      @properties.each {|prop| document[prop] = node.send(prop)}
    end
  end


  # If node class A has a relation with type 'd' to node class B
  #   A.x -d-> B.y  A.index d.y
  # Then
  #   indexer = RelationIndexer.new('d','d').properties << 'y'
  #   IndexTrigger.instance_for(B) << indexer
  #   IndexUpdater.instance_for(A) << indexer
  # If property y on a B node changes then all its nodes in the relation 'd' will
  # be reindexed.  Those nodes (which will be of type node class A) will use the same RelationIndexer to update the
  # index document with key field 'd.y' and values of property y of all nodes in the
  # relationship 'd'
  # 
  #
  class RelationIndexer
    attr_reader :rel_type, :properties
    
    def initialize(rel_name, rel_type)
      @properties = []
      @rel_type = rel_type
      @rel_name = rel_name
    end

    def on_property_changed?(property)
      @properties.include?(property)
    end

    def on_relation_created_or_deleted?(rel_type)
      @rel_type == rel_type
    end

    def nodes_to_be_reindexed(node)
      node.relations.both(@rel_type).nodes
    end

    def index_key(property)
      "#@rel_name.#{property}".to_sym
    end

    def update_document(document, node)
      return if node.deleted?

      relations = node.relations.both(@rel_type).nodes
      relations.each do |other_node|
        next if other_node.deleted?
        @properties.each do |p|
          index_key = index_key(p)
          document[index_key] ||= []
          document[index_key] << other_node.send(p)
        end
      end
    end
  end

end