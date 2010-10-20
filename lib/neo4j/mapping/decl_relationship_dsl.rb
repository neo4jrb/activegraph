module Neo4j::Mapping


  # A DSL for declared relationships has_n and has_one
  # This DSL will be used to create accessor methods for relationships.
  # Instead of using the 'raw' Neo4j::NodeMixin#rels method where one needs to know
  # the name of relationship and direction one can use the generated accessor methods.
  #
  # The DSL can also be used to specify a mapping to a Ruby class for a relationship, see Neo4j::Relationships::DeclRelationshipDsl#relationship
  #
  # ==== Example
  #
  #   class Folder
  #      include Neo4j::NodeMixin
  #      property :name
  #      # Declaring a Many relationship to any other node
  #      has_n(:files)
  #    end
  #
  #   class File
  #     include Neo4j::NodeMixin
  #     # declaring a incoming relationship from Folder's relationship files
  #     has_one(:folder).from(Folder, :files)
  #   end
  #
  # The following methods will be generated:
  # <b>Folder#files</b> ::      returns an Enumerable of outgoing nodes for relationship 'files'
  # <b>Folder#files_rels</b> :: returns an Enumerable of outgoing relationships for relationship 'files'
  # <b>File#folder</b> ::       for adding one node for the relationship 'files' from the outgoing Folder node
  # <b>File#folder_rel</b> ::   for accessing relationship 'files' from the outgoing Folder node
  # <b>File#folder</b> ::       for accessing nodes from relationship 'files' from the outgoing Folder node
  #
  class DeclRelationshipDsl
    include Neo4j::ToJava

    attr_reader :to_type, :to_class, :cascade_delete_prop_name, :counter, :rel_id, :direction
    CASCADE_DELETE_PROP_NAMES = {:outgoing => :_cascade_delete_outgoing, :incoming => :_cascade_delete_incoming}

    def initialize(rel_id, has_one, params)
      @direction = :outgoing
      @rel_id = rel_id
      @to_type = rel_id
      @has_one = has_one
      @namespace_type = rel_id
      @cascade_delete_prop_name = CASCADE_DELETE_PROP_NAMES[params[:cascade_delete]]
      @counter = params[:counter] == true
    end

    def has_one?
      @has_one
    end

    # If a counter was specified in the dsl for counting number of nodes in this relationship.
    #
    def counter?
      @counter
    end

    # If cascade delete was specified for this relationship
    #
    def cascade_delete?
      !@cascade_delete_prop_name.nil?
    end

    def class_and_type_from_args(args) # :nodoc:
      if (args.size > 1)
        return args[0], args[1]
      else
        return args[0], @rel_id
      end
    end


    # The actual relationship type that this DSL will use
    def namespace_type
      @to_class.nil? ? @to_type.to_s : "#{@to_class.to_s}##{@to_type.to_s}"
    end

    def each_node(node, direction, &block)
      type = type_to_java(namespace_type)
      dir  = dir_to_java(direction)
      node._java_node.getRelationships(type, dir).each do |rel|
        other = rel.getOtherNode(node).wrapper
        block.call other
      end
    end

    def incoming?
      @direction == :incoming
    end

    def incoming_dsl
      dsl = to_class._decl_rels[to_type]
      raise "Unspecified outgoing relationship '#{to_type}' for incoming relationship '#{rel_id}' on class #{to_class}" if dsl.nil?
      dsl
    end

    def single_node(node)
      rel = single_relationship(node)
      rel && rel.other_node(node).wrapper
    end

    def single_relationship(node)
      dir = direction
      dsl = incoming? ? incoming_dsl : self

      type     = type_to_java(dsl.namespace_type)
      java_dir = dir_to_java(dir)
      rel = node._java_node.getSingleRelationship(type, java_dir)
      rel && rel.wrapper
    end

    def all_relationships(node)
      dsl = incoming? ? incoming_dsl : self
      type = type_to_java(dsl.namespace_type)
      dir  = dir_to_java(direction)
      node._java_node.getRelationships(type, dir)
    end

    def create_relationship_to(node, other)
      dsl = incoming? ? incoming_dsl : self

      # If the are creating an incoming relationship we need to swap incoming and outgoing nodes
      if @direction == :outgoing
        from, to = node, other
      else
        from, to = other, node
      end

      java_type = type_to_java(dsl.namespace_type)

      rel = from._java_node.create_relationship_to(to._java_node, java_type)
      rel[:_classname] =  dsl.relationship_class.to_s if dsl.relationship_class

      # TODO - not implemented yet
      # the from.neo_id is only used for cascade_delete_incoming since that node will be deleted when all the list items has been deleted.
      # if cascade_delete_outgoing all nodes will be deleted when the root node is deleted
      # if cascade_delete_incoming then the root node will be deleted when all root nodes' outgoing nodes are deleted
      #rel[@dsl.cascade_delete_prop_name] = node.neo_id if @dsl.cascade_delete?
      rel.wrapper
    end

    # Specifies an outgoing relationship.
    # The name of the outgoing class will be used as a prefix for the relationship used.
    #
    # ==== Arguments
    # clazz:: to which class this relationship goes
    # relationship:: optional, the relationship to use
    #
    # ==== Example
    #   class FolderNode
    #     include Neo4j::NodeMixin
    #     has_n(:files).to(FileNode)
    #   end
    #
    #  folder = FolderNode.new
    #  # generate a relationship between folder and file of type 'FileNode#files'
    #  folder.files << FileNode.new
    #
    def to(*args)
      @direction = :outgoing
      @to_class, @to_type = class_and_type_from_args(args)
      self
    end

    # Specifies an incoming relationship.
    # Will use the outgoing relationship given by the from class.
    #
    # ==== Example
    #   class FolderNode
    #     include Neo4j::NodeMixin
    #     has_n(:files).to(FileNode)
    #   end
    #
    #  class FileNode
    #    include Neo4j::NodeMixin
    #    has_one(:folder).from(FileNode, :files)
    #  end
    #
    #  file = FileNode.new
    #  # create an outgoing relationship of type 'FileNode#files' from folder node to file
    #  file.folder = FolderNode.new
    #
    def from(*args)
      #(clazz, type)
      @direction = :incoming
      @to_class, @to_type = class_and_type_from_args(args)
      self
    end

    # Specifies which relationship ruby class to use for the relationship
    #
    # ==== Example
    #
    #   class OrderLine
    #     include Neo4j::RelationshipMixin
    #     property :units
    #     property :unit_price
    #   end
    #
    #   class Order
    #     property :total_cost
    #     property :dispatched
    #     has_n(:products).to(Product).relationship(OrderLine)
    #   end
    #
    #  order = Order.new
    #  order.products << Product.new
    #  order.products_rels.first # => OrderLine
    #
    def relationship(rel_class)
      @relationship = rel_class
      self
    end

    def relationship_class # :nodoc:
      @relationship
    end
  end
end
