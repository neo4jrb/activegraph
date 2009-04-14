module Neo4j

  # This class is responsible for both knowing which nodes that needs to be reindexed
  # and how to perform the reindex operation (the document_updaters attribute).
  # 
  # There is one Indexer per Node root class.
  #
  class Indexer
    attr_reader :document_updaters, :index_id
    attr_reader :property_indexer # for testing purpose
    
    def initialize(indexed_class)
      @relation_indexers = {}
      @property_indexer = PropertyIndexer.new
      @document_updaters = [@property_indexer]
      # the file name of the lucene index if kept on disk
      @index_id = "/" + indexed_class.to_s.gsub('::', '/')
    end

    # Returns the Indexer for the given Neo4j::NodeMixin class
    # :api:private
    def self.instance(clazz)
      @instances ||= {}
      @instances[clazz.root_class] ||= Indexer.new(clazz.root_class)
      @instances[clazz.root_class]
    end

    # only for testing purpose, e.g we need to redefine an existing class
    def self.remove_instance(clazz)
      @instances.delete(clazz.root_class) unless @instances.nil?
    end

    # only for testing purpose, e.g we need to redefine an existing class
    def self.clear_all_instances
      @instances = nil
    end

    # (Re)index the given node
    # :api: private
    def self.index(node)
      indexer = instance(node.class)
      indexer.index(node)
    end

    # :api: private
    def find(query,block)
      SearchResult.new lucene_index, query, &block
    end

    # :api: private
    def add_index_on_property(prop)
      @property_indexer.properties << prop.to_sym
    end

    # :api: private
    def remove_index_on_property(prop)
      @property_indexer.properties.delete prop.to_sym
    end

    # :api: private
    def add_index_in_relation_on_property(updater_clazz, rel_name, rel_type, prop)
      unless relation_indexer_for?(rel_type.to_sym)
        indexer = new_relation_indexer_for(rel_type.to_sym, rel_name.to_sym)
        self.class.instance(updater_clazz).document_updaters << indexer
      end

      # TODO make sure the same index is not added twice
      relation_indexer_for(rel_type.to_sym).properties << prop.to_sym
    end

    # :api: private
    def index(node)
      document = {:id => node.neo_node_id }

      @document_updaters.each do |updater|
        updater.update_document(document, node)
      end

      lucene_index << document
    end

    # :api: private
    def delete_index(node)
      lucene_index.delete(node.neo_node_id)
    end


    # :api: private
    def lucene_index
      Lucene::Index.new(@index_id)
    end

    # :api: private
    def field_infos
      lucene_index.field_infos
    end

    # :api: private
    def on_property_changed(node, prop)
      @relation_indexers.values.each {|indexer| indexer.on_property_changed(node, prop.to_sym)}
      @property_indexer.on_property_changed(node,prop.to_sym)
    end

    # :api: private
    def on_relation_created(node, rel_type)
      @relation_indexers.values.each {|indexer| indexer.on_relation_created(node, rel_type.to_sym)}
    end

    # :api: private
    def on_relation_deleted(node, rel_type)
      @relation_indexers.values.each {|indexer| indexer.on_relation_deleted(node, rel_type.to_sym)}
    end

    # :api: private
    def relation_indexer_for(rel_type)
      @relation_indexers[rel_type.to_sym]
    end

    # :api: private
    def relation_indexer_for?(rel_type)
      !relation_indexer_for(rel_type.to_sym).nil?
    end

    # :api: private
    def new_relation_indexer_for(rel_type, rel_name)
      @relation_indexers[rel_type.to_sym] = RelationIndexer.new(rel_name.to_sym, rel_type.to_sym)
    end

  end


  # :api: private
  class PropertyIndexer
    attr_reader :properties

    def initialize
      @properties = []
    end

    # :api: private
    def on_property_changed(node, prop)
      Indexer.index(node) if @properties.include?(prop)
    end

    # :api: private
    def update_document(document, node)
      @properties.each {|prop| document[prop.to_sym] = node.send(prop)}
    end
  end


  # If node class A has a relation with type 'd' to node class B
  #   A.x -d-> B.y  A.index d.y
  # If property y on a B node changes then all its nodes in the relation 'd' will
  # be reindexed.  Those nodes (which will be of type node class A) will use the same RelationIndexer to update the
  # index document with key field 'd.y' and values of property y of all nodes in the
  # relationship 'd'
  # 
  # :api: private
  class RelationIndexer
    attr_reader :rel_type, :properties
    
    def initialize(rel_name, rel_type)
      @properties = []
      @rel_type = rel_type
      @rel_name = rel_name
    end

    # :api: private
    def on_property_changed(node, prop)
      # make sure we're interested in indexing this property
      reindex_related_nodes(node) if @properties.include?(prop)
    end

    # :api: private
    def on_relation_deleted(node, rel_type)
      Indexer.index(node) if @rel_type == rel_type
    end

    # :api: private
    def on_relation_created(node, rel_type)
      # make sure we're interested in indexing this relation
      if @rel_type == rel_type
        reindex_related_nodes(node)
        Indexer.index(node)
      end
    end

    # :api: private
    def reindex_related_nodes(node)
      related_nodes = node.relations.both(@rel_type).nodes
      related_nodes.each do |related_node|
        Indexer.index(related_node)
      end
    end

    # :api: private
    def index_key(property)
      "#@rel_name.#{property}".to_sym
    end

    # :api: private
    def update_document(document, node)
      relations = node.relations.both(@rel_type).nodes
      relations.each do |other_node|
        @properties.each do |p|
          index_key = index_key(p)
          document[index_key] ||= []
          document[index_key] << other_node.send(p)
        end
      end
    end
  end

end
