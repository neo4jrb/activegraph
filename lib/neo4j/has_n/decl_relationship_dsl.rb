module Neo4j
  module HasN


    # A DSL for declared relationships has_n and has_one
    # This DSL will be used to create accessor methods for relationships.
    # Instead of using the 'raw' Neo4j::NodeMixin#rels method where one needs to know
    # the name of relationship and direction one can use the generated accessor methods.
    #
    # The DSL can also be used to specify a mapping to a Ruby class for a relationship, see Neo4j::HasN::DeclRelationshipDsl#relationship
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

      attr_reader :target_class, :source_class, :dir, :rel_type

      def initialize(method_id, has_one, target_class)
        @dir = :outgoing
        @method_id = method_id
        @has_one = has_one
        @rel_type = method_id
        @target_class = target_class
        @source_class = target_class
      end

      def to_s
        "DeclRelationshipDsl #{object_id} dir: #{@dir} rel_id: #{@method_id}, rel_type: #{@rel_type}, target_class:#{@target_class} rel_class:#{@relationship}"
      end

      def has_one?
        @has_one
      end

      def has_n?
        !@has_one
      end

      def java_rel_type
        type_to_java(@rel_type)
      end

      def java_dir
        dir_to_java(@dir)
      end

      def each_node(node, &block) #:nodoc:
        node._java_node.getRelationships(java_rel_type, java_dir).each do |rel|
          block.call(rel.getOtherNode(node).wrapper)
        end
      end

      def _each_node(node, &block) #:nodoc:
        node._java_node.getRelationships(java_rel_type, java_dir).each do |rel|
          block.call rel.getOtherNode(node)
        end
      end

      def incoming? #:nodoc:
        @dir == :incoming
      end

      def single_node(node) #:nodoc:
        rel = single_relationship(node)
        rel && rel.other_node(node).wrapper
      end

      def single_relationship(node) #:nodoc:
        node._java_node.rel(dir, rel_type)
      end

      def _all_relationships(node) #:nodoc:
        node._java_node.getRelationships(java_rel_type, java_dir)
      end

      def all_relationships(node) #:nodoc:
        Neo4j::Rels::Traverser.new(node._java_node, [rel_type], dir)
      end

      def create_relationship_to(node, other) # :nodoc:
        from, to = incoming? ? [other, node] : [node, other]

        if relationship_class
          relationship_class.new(@rel_type, from._java_node, to._java_node)
        else
          from._java_node.create_relationship_to(to._java_node, java_rel_type)
        end
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
      # ==== Example, without prefix
      #
      #   class FolderNode
      #     include Neo4j::NodeMixin
      #     has_n(:files).to(:contains)
      #   end
      #
      #   file = FileNode.new
      #   # create an outgoing relationship of type 'contains' from folder node to file
      #   folder.files << FolderNode.new
      #
      def to(target)
        @dir = :outgoing

        if (Class === target)
          # handle e.g. has_n(:friends).to(class)
          @target_class = target
          @rel_type = "#{@source_class}##{@method_id}"
        elsif (Symbol === target)
          # handle e.g. has_n(:friends).to(:knows)
          @rel_type = target.to_s
        else
          raise "Expected a class or a symbol for, got #{target}/#{target.class}"
        end
        self
      end

      # Specifies an incoming relationship.
      # Will use the outgoing relationship given by the from class.
      #
      # ==== Example, with prefix FileNode
      #   class FolderNode
      #     include Neo4j::NodeMixin
      #     has_n(:files).to(FileNode)
      #   end
      #
      #   class FileNode
      #     include Neo4j::NodeMixin
      #     # will only traverse any incoming relationship of type files from node FileNode
      #     has_one(:folder).from(FolderNode, :files)
      #   end
      #
      #   file = FileNode.new
      #   # create an outgoing relationship of type 'FileNode#files' from folder node to file (FileNode is the prefix).
      #   file.folder = FolderNode.new
      #
      # ==== Example, without prefix
      #
      #   class FolderNode
      #     include Neo4j::NodeMixin
      #     has_n(:files)
      #   end
      #
      #   class FileNode
      #     include Neo4j::NodeMixin
      #     has_one(:folder).from(:files)  # will traverse any incoming relationship of type files
      #   end
      #
      #   file = FileNode.new
      #   # create an outgoing relationship of type 'files' from folder node to file
      #   file.folder = FolderNode.new
      #
      #
      def from(*args)
        @dir = :incoming

        if (args.size > 1)
          # handle specified (prefixed) relationship, e.g. has_n(:known_by).from(clazz, :type)
          @target_class = args[0]
          @rel_type = "#{@target_class}##{args[1]}"
          @relationship_name = args[1]
        elsif (Symbol === args[0])
          # handle unspecified (unprefixed) relationship, e.g. has_n(:known_by).from(:type)
          @rel_type = args[0]
        else
          raise "Expected a symbol for, got #{args[0]}"
        end
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
        if !@relationship_name.nil? && @relationship.nil?
          other_class_dsl = @target_class._decl_rels[@relationship_name]
          if other_class_dsl
            @relationship = other_class_dsl.relationship_class
          else
            Neo4j.logger.warn "Unknown outgoing relationship #{@relationship_name} on #{@target_class}"
          end
        end
        @relationship
      end
    end
  end
end
