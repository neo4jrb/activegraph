module Neo4j
  module ActiveNode
    module HasN


      # A DSL for declared relationships has_n and has_one
      # This DSL will be used to create accessor methods for relationships.
      # Instead of using the 'raw' Neo4j::ActiveNode#rels method where one needs to know
      # the name of relationship and direction one can use the generated accessor methods.
      #
      # @example
      #
      #   class Folder
      #      include Neo4j::ActiveNode
      #      property :name
      #      # Declaring a Many relationship to any other node
      #      has_n(:files)
      #    end
      #
      #   class File
      #     include Neo4j::ActiveNode
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
      class DeclRel
        attr_reader :source_class, :dir, :rel_type, :method_id

        def initialize(method_id, has_one, source_class, *callbacks)
          @method_id = method_id
          @has_one = has_one
          @dir = :outgoing
          @rel_type = method_id.to_sym
          @source_class = source_class
          unless callbacks.empty?
            @before_callback = callbacks.first[:before] || nil
            @after_callback = callbacks.first[:after] || nil
          end
        end

        def inherit_new
          base = self
          dr = DeclRel.new(@method_id, @has_one, @source_class)
          dr.instance_eval do
            @dir = base.dir
            @rel_type = base.rel_type
            @target_name = base.target_name if base.target_name
            @source_class = base.source_class
          end
          dr
        end

        def to_s
          "DeclRel one #{has_one?}, dir: #{@dir}, rel_id: #{@method_id}, rel_type: #{@rel_type}, target_class:#{@target_name}"
        end

        def inspect
          to_s
        end

        # @return [true, false]
        def has_one?
          @has_one
        end

        # @return [true, false]
        def has_n?
          !@has_one
        end

        # @return [true,false]
        def incoming? #:nodoc:
          @dir == :incoming
        end


        # Declares an outgoing relationship type.
        # It is possible to prefix relationship types so that it's possible to distinguish different incoming relationships.
        # There is no validation that the added node is of the specified class.
        #
        # @example Example
        #   class FolderNode
        #     include Neo4j::ActiveNode
        #     has_n(:files).to(FileNode)
        #     has_one(:root).to("FileSystem") # also possible, if the class is not defined yet
        #   end
        #
        #  folder = FolderNode.new
        #  # generate a relationship between folder and file of type 'FileNode#files'
        #  folder.files << FileNode.new
        #
        # @example relationship with a hash, user defined relationship
        #
        #   class FolderNode
        #     include Neo4j::ActiveNode
        #     has_n(:files).to('FolderNode#files')
        #   end
        #
        # @example without prefix
        #
        #   class FolderNode
        #     include Neo4j::ActiveNode
        #     has_n(:files).to(:contains)
        #   end
        #
        #   file = FileNode.new
        #   # create an outgoing relationship of type 'contains' from folder node to file
        #   folder.files << FolderNode.new
        #
        # @param [Class, String, Symbol] target the other class to which this relationship goes (if String or Class) or the relationship (if Symbol)
        # @param [String, Symbol] rel_type the rel_type postfix for the relationships, which defaults to the same as the has_n/one method id
        # @return self
        def to(target, rel_type = @method_id)
          @dir = :outgoing

          case target
            when /#/
              @target_name, _ = target.to_s.split("#")
              @rel_type = target.to_sym
            when Class, String
              @target_name = target.to_s
              @rel_type = "#{@source_class}##{rel_type}".to_sym
            when Symbol
              @target_name = nil
              @rel_type = target.to_sym
            else
              raise "Expected a class or a symbol for, got #{target}/#{target.class}"
          end
          self
        end

        # Specifies an incoming relationship.
        # Will use the outgoing relationship given by the from class.
        #
        # @example with prefix FileNode
        #   class FolderNode
        #     include Neo4j::NodeMixin
        #     has_n(:files).to(FileNode)
        #   end
        #
        #   class FileNode
        #     include Neo4j::NodeMixin
        #     # will only traverse any incoming relationship of type files from node FileNode
        #     has_one(:folder).from(FolderNode.files)
        #     # alternative: has_one(:folder).from(FolderNode, :files) 
        #   end
        #
        #   file = FileNode.new
        #   # create an outgoing relationship of type 'FileNode#files' from folder node to file (FileNode is the prefix).
        #   file.folder = FolderNode.new
        #
        # @example without prefix
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
        def from(target, rel_type=@method_id)
          @dir = :incoming

          case target
            when /#/
              @target_name, _ = target.to_s.split("#")
              @rel_type = target
            when Class, String
              @target_name = target.to_s
              @rel_type = "#{@target_name}##{rel_type}".to_sym
            when Symbol
              @target_name = nil
              @rel_type = target.to_sym
            else
              raise "Expected a class or a symbol for, got #{target}/#{target.class}"
          end
          self
        end


        # @private
        def target_name
          @target_name
        end

        def target_class
          @target_name && @target_name.split("::").inject(Kernel) { |container, name| container.const_get(name.to_s) }
        end


        # @private
        def each_node(node, &block)
          node.nodes(dir: dir, type: rel_type).each { |n| block.call(n) }
        end

        def all_relationships(node)
          to_enum(:each_rel, node)
        end

        def each_rel(node, &block) #:nodoc:
          node.rels(dir: dir, type: rel_type).each { |rel| block.call(rel) }
        end

        def single_relationship(node)
          node.rel(dir: dir, type: rel_type)
        end

        def single_node(node)
          node.node(dir: dir, type: rel_type)
        end

        # @private
        def create_relationship_to(node, other, relationship_props={}) # :nodoc:
          from, to = incoming? ? [other, node] : [node, other]
          before_callback_result = do_before_callback(node, from, to)
          return false if before_callback_result == false

          result = from.create_rel(@rel_type, to, relationship_props)

          after_callback_result = do_after_callback(node, from, to)
          after_callback_result == false ? false : result
        end

        private

        def do_before_callback(caller, from, to)
          @before_callback ? caller.send(@before_callback, from, to) : true
        end

        def do_after_callback(caller, from, to)
          @after_callback ? caller.send(@after_callback, from, to) : true
        end

      end
    end
  end
end
