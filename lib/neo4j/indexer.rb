module Neo4j

  # This class is responsible for both knowing which nodes that needs to be reindexed
  # and how to perform the reindex operation (the document_updaters attribute).
  # 
  # There is one Indexer per Node root class.
  #
  class Indexer  #:nodoc:
    attr_reader :document_updaters, :index_id
    attr_reader :property_indexer # for testing purpose
    
    def initialize(indexed_class, query_for_nodes)
      @relationship_indexers = {}
      @query_for_nodes = query_for_nodes
      @property_indexer = PropertyIndexer.new
      @document_updaters = [@property_indexer]
      # the file name of the lucene index if kept on disk
      @index_id = "/" + indexed_class.to_s.gsub('::', '/')
    end

    # Returns the Indexer for the given Neo4j::NodeMixin class
    def self.instance(clazz, query_for_nodes = true)
      @instances ||= {}
      @instances[clazz.root_class] ||= Indexer.new(clazz.root_class, query_for_nodes)
      @instances[clazz.root_class]
    end

    # only for testing purpose, e.g we need to redefine an existing class
    def self.remove_instance(clazz)
      @instances.delete(clazz.root_class) if !@instances.nil? && clazz.respond_to?(:root_class)
    end


    # (Re)index the given node
    def self.index(node)
      indexer = instance(node.class)
      indexer.index(node)
    end

    def find(query,block)
      SearchResult.new lucene_index, query, @query_for_nodes, &block
    end

    def add_index_on_property(prop)
      @property_indexer.properties << prop.to_sym
    end

    def remove_index_on_property(prop)
      @property_indexer.properties.delete prop.to_sym
    end

    def add_index_in_relationship_on_property(updater_clazz, rel_name, rel_type, prop, namespace_type)
      unless relationship_indexer_for?(namespace_type)
        indexer = new_relationship_indexer_for(namespace_type, rel_name.to_sym)
        self.class.instance(updater_clazz).document_updaters << indexer
      end

      # TODO make sure the same index is not added twice
      relationship_indexer_for(namespace_type).properties << prop.to_sym
    end

    def index(node)
      document = {:id => node.neo_id }

      @document_updaters.each do |updater|
        updater.update_document(document, node)
      end

      lucene_index << document
    end

    def delete_index(node)
      lucene_index.delete(node.neo_id)
    end


    def lucene_index
      Lucene::Index.new(@index_id)
    end

    def field_infos
      lucene_index.field_infos
    end

    def on_property_changed(node, prop)
      @relationship_indexers.values.each {|indexer| indexer.on_property_changed(node, prop.to_sym)}
      @property_indexer.on_property_changed(node,prop.to_sym)
    end

    def on_relationship_created(node, rel_type)
      @relationship_indexers.values.each {|indexer| indexer.on_relationship_created(node, rel_type.to_sym)}
    end

    def on_relationship_deleted(node, rel_type)
      @relationship_indexers.values.each {|indexer| indexer.on_relationship_deleted(node, rel_type.to_sym)}
    end

    def relationship_indexer_for(rel_type)
      @relationship_indexers[rel_type.to_sym]
    end

    def relationship_indexer_for?(rel_type)
      !relationship_indexer_for(rel_type.to_sym).nil?
    end

    def new_relationship_indexer_for(rel_type, rel_name)
      @relationship_indexers[rel_type.to_sym] = RelationshipIndexer.new(rel_name.to_sym, rel_type.to_sym)
    end

  end


  class PropertyIndexer #:nodoc:
    attr_reader :properties

    def initialize
      @properties = []
    end

    def on_property_changed(node, prop)
      Indexer.index(node) if @properties.include?(prop)
    end

    def update_document(document, node)
      # we have to check that the property exists since the index can be defined in a subclass
      @properties.each {|prop| document[prop.to_sym] = node.send(prop) if node.respond_to?(prop)}
    end
  end


  # If node class A has a relationship with type 'd' to node class B
  #   A.x -d-> B.y  A.index d.y
  # If property y on a B node changes then all its nodes in the relationship 'd' will
  # be reindexed.  Those nodes (which will be of type node class A) will use the same RelationshipIndexer to update the
  # index document with key field 'd.y' and values of property y of all nodes in the
  # relationship 'd'
  # 
  class RelationshipIndexer #:nodoc:
    attr_reader :rel_type, :properties
    
    def initialize(rel_name, rel_type)
      @properties = []
      @rel_type = rel_type
      @rel_name = rel_name
    end

    def on_property_changed(node, prop)
      # make sure we're interested in indexing this property
      reindex_related_nodes(node) if @properties.include?(prop)
    end

    def on_relationship_deleted(node, rel_type)
      Indexer.index(node) if @rel_type == rel_type
    end

    def on_relationship_created(node, rel_type)
      # make sure we're interested in indexing this relationship
      if @rel_type == rel_type
        reindex_related_nodes(node)
        Indexer.index(node)
      end
    end

    def reindex_related_nodes(node)
      related_nodes = node.rels.both(@rel_type).nodes
      related_nodes.each do |related_node|
        Indexer.index(related_node)
      end
    end

    def index_key(property)
      "#@rel_name.#{property}".to_sym
    end

    def update_document(document, node)
      relationships = node.rels.both(@rel_type).nodes
      relationships.each do |other_node|
        @properties.each do |p|
          index_key = index_key(p)
          document[index_key] ||= []
          document[index_key] << other_node.send(p)
        end
      end
    end
  end

end
