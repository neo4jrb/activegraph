module Neo4j::ActiveNode
  module HasN
    extend ActiveSupport::Concern

    def _decl_rels_for(rel_type)
      self.class._decl_rels[rel_type]
    end


    module ClassMethods

      def has_association?(name)
        !!associations[name]
      end

      def associations
        @associations || {}
      end

      def has_relationship?(rel_type)
        !!_decl_rels[rel_type]
      end

      def has_one_relationship?(rel_type)
        has_relationship?(rel_type) && _decl_rels[rel_type].has_one?
      end

      def relationship_dir(rel_type)
        has_relationship?(rel_type) && _decl_rels[rel_type].dir
      end

      def _decl_rels
        @_decl_rels ||= {}
      end

      # make sure the inherited classes inherit the <tt>_decl_rels</tt> hash
      def inherited(klass)
        copy = _decl_rels.clone
        copy.each_pair { |k, v| copy[k] = v.inherit_new }
        klass.instance_variable_set(:@_decl_rels, copy)
        super
      end


      # Specifies a relationship between two node active node classes.
      # Generates assignment and accessor methods for the given relationship.
      # Both incoming and outgoing relationships can be declared, see {Neo4j::ActiveNode::HasN::DeclRel}
      #
      # @example has_n(:files)
      #
      #   class FolderNode
      #      include Neo4j::ActiveNode
      #      has_n(:files)
      #   end
      #
      #   folder = FolderNode.new
      #   folder.files << Neo4j::Node.new << Neo4j::Node.new
      #   folder.files.inject {...}
      #
      #   FolderNode.files #=> 'files' the name of the relationship
      #
      # @example has_n(x).to(...)
      #
      #   # You can declare which class it has relationship to.
      #   # The generated relationships will be prefixed with the name of that class.
      #   class FolderNode
      #      include Neo4j::ActiveNode
      #      has_n(:files).to(File)
      #      # Same as has_n(:files).to("File")
      #   end
      #
      #   FolderNode.files #=> 'File#files' the name of the relationship
      #
      # @example has_one(x).from(class, has_one_name)
      #
      #   # generate accessor method for traversing and adding relationship on incoming nodes.
      #   class FileNode
      #      include Neo4j::ActiveNode
      #      has_one(:folder).from(FolderNode.files)
      #      # or same as
      #      has_one(:folder).from(FolderNode, :files)
      #   end
      #
      #
      # @return [Neo4j::ActiveNode::HasN::DeclRel] a DSL object where the has_n relationship can be further specified
      def has_n(rel_type)
        clazz = self
        module_eval(%Q{def #{rel_type}=(values)
                  #{rel_type}_rels.each {|rel| rel.del }

                  dsl = _decl_rels_for('#{rel_type}'.to_sym)
                  values.each do |value|
                    dsl.create_relationship_to(self, value)
                  end
              end}, __FILE__, __LINE__)

        module_eval(%Q{
                def #{rel_type}()
                    dsl = _decl_rels_for('#{rel_type}'.to_sym)
                    Neo4j::ActiveNode::HasN::Nodes.new(self, dsl)
                end}, __FILE__, __LINE__)

        module_eval(%Q{
                def #{rel_type}_rels
                    dsl = _decl_rels_for('#{rel_type}'.to_sym)
                    dsl.all_relationships(self)
                end}, __FILE__, __LINE__)


        instance_eval(%Q{
          def #{rel_type}
            _decl_rels[:#{rel_type}].rel_type
          end}, __FILE__, __LINE__)

        _decl_rels[rel_type.to_sym] = DeclRel.new(rel_type, false, clazz)
      end

      def has_many(direction, name, options = {})
        name = name.to_sym

        association = Neo4j::ActiveNode::HasN::Association.new(:has_many, direction, name, options)
        name = name.to_sym

        @associations ||= {}
        @associations[name] = association

        target_class_name = association.target_class_name || 'nil'

        # TODO: Make assignment more efficient? (don't delete nodes when they are being assigned)
        module_eval(%Q{
          def #{name}(node = nil, rel = nil)
            Neo4j::ActiveNode::Query::QueryProxy.new(#{target_class_name}, self.class.associations[#{name.inspect}], session: self.class.neo4j_session, start_object: self, node: node, rel: rel)
          end

          def #{name}=(other_nodes)
            #{name}(nil, :r).query_as(:n).delete(:r).exec

            other_nodes.each do |node|
              #{name} << node
            end
          end}, __FILE__, __LINE__)

        instance_eval(%Q{
          def #{name}(node = nil, rel = nil)
            Neo4j::ActiveNode::Query::QueryProxy.new(#{target_class_name}, @associations[#{name.inspect}], session: self.neo4j_session, query_proxy: self.query_proxy, node: node, rel: rel)
          end}, __FILE__, __LINE__)

      end

      def has_one(direction, name, options = {})
        name = name.to_sym

        association = Neo4j::ActiveNode::HasN::Association.new(:has_one, direction, name, options)
        name = name.to_sym

        @associations ||= {}
        @associations[name] = association

        target_class_name = association.target_class_name || 'nil'

        module_eval(%Q{
          def #{name}=(other_node)
            #{name}_query_proxy(rel: :r).query_as(:n).delete(:r).exec

            #{name}_query_proxy << other_node
          end

          def #{name}_query_proxy(options = {})
            self.class.#{name}_query_proxy({start_object: self}.merge(options))
          end

          def #{name}_rel
            #{name}_query_proxy(rel: :r).pluck(:r).first
          end

          def #{name}(node = nil, rel = nil)
            #{name}_query_proxy(node: node, rel: rel).first
          end}, __FILE__, __LINE__)

        instance_eval(%Q{
          def #{name}_query_proxy(options = {})
            Neo4j::ActiveNode::Query::QueryProxy.new(#{target_class_name}, @associations[#{name.inspect}], {session: self.neo4j_session}.merge(options))
          end

          def #{name}(node = nil, rel = nil)
            #{name}_query_proxy(query_proxy: self.query_proxy, node: node, rel: rel)
          end}, __FILE__, __LINE__)

      end


    end
  end

end
