module Neo4j::ActiveNode
  module HasN
    extend ActiveSupport::Concern
    include Neo4j::ActiveNode::HasN::AssociationCache

    class NonPersistedNodeError < StandardError; end

    def association_reflection(association_obj)
      self.class.reflect_on_association(association_obj.name)
    end

    module ClassMethods
      # :nocov:
      # rubocop:disable Style/PredicateName
      def has_association?(name)
        ActiveSupport::Deprecation.warn 'has_association? is deprecated and may be removed from future releases, use association? instead.', caller

        association?(name)
      end
      # rubocop:enable Style/PredicateName
      # :nocov:

      def association?(name)
        !!associations[name.to_sym]
      end

      def associations
        @associations || {}
      end

      # make sure the inherited classes inherit the <tt>_decl_rels</tt> hash
      def inherited(klass)
        klass.instance_variable_set(:@associations, associations.clone)
        super
      end

      # rubocop:disable Style/PredicateName
      def has_many(direction, name, options = {})
        name = name.to_sym
        association = build_association(:has_many, direction, name, options)
        # TODO: Make assignment more efficient? (don't delete nodes when they are being assigned)
        module_eval(%{
          def #{name}(node = nil, rel = nil)
            return [].freeze unless self._persisted_obj
            #{name}_query_proxy(node: node, rel: rel)
          end

          def #{name}_query_proxy(options = {})
            Neo4j::ActiveNode::Query::QueryProxy.new(#{association.target_class_name_or_nil},
                                                     self.class.associations[#{name.inspect}],
                                                     {
                                                       session: self.class.neo4j_session,
                                                       start_object: self,
                                                       node: options[:node],
                                                       rel: options[:rel],
                                                       context: '#{self.name}##{name}',
                                                       caller: self
                                                     })
          end

          def #{name}=(other_nodes)
            #{name}(nil, :r).query_as(:n).delete(:r).exec
            clear_association_cache
            other_nodes.each { |node| #{name} << node }
          end

          def #{name}_rels
            #{name}(nil, :r).pluck(:r)
          end}, __FILE__, __LINE__)

        instance_eval(%{
          def #{name}(node = nil, rel = nil, proxy_obj = nil)
            #{name}_query_proxy(node: node, rel: rel, proxy_obj: proxy_obj)
          end

          def #{name}_query_proxy(options = {})
            query_proxy = options[:proxy_obj] || Neo4j::ActiveNode::Query::QueryProxy.new(::#{self.name}, nil, {
                  session: self.neo4j_session, query_proxy: nil, context: '#{self.name}' + '##{name}'
                })
            context = (query_proxy && query_proxy.context ? query_proxy.context : '#{self.name}') + '##{name}'
            Neo4j::ActiveNode::Query::QueryProxy.new(#{association.target_class_name_or_nil},
                                                     associations[#{name.inspect}],
                                                     {
                                                       session: self.neo4j_session,
                                                       query_proxy: query_proxy,
                                                       node: options[:node],
                                                       rel: options[:rel],
                                                       context: context,
                                                       optional: query_proxy.optional?,
                                                       caller: query_proxy.caller
                                                     })
          end}, __FILE__, __LINE__)
      end

      def has_one(direction, name, options = {})
        name = name.to_sym
        association = build_association(:has_one, direction, name, options)

        module_eval(%{
          def #{name}=(other_node)
            raise(Neo4j::ActiveNode::HasN::NonPersistedNodeError, 'Unable to create relationship with non-persisted nodes') unless self._persisted_obj
            clear_association_cache
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
            return nil unless self._persisted_obj
            result = #{name}_query_proxy(node: node, rel: rel, context: '#{self.name}##{name}')
            association = self.class.reflect_on_association(__method__)
            query_return = association_instance_get(result.to_cypher_with_params, association)
            query_return || association_instance_set(result.to_cypher_with_params, result.first, association)
          end}, __FILE__, __LINE__)

        instance_eval(%{
          def #{name}_query_proxy(options = {})
            Neo4j::ActiveNode::Query::QueryProxy.new(#{association.target_class_name_or_nil},
                                                     associations[#{name.inspect}],
                                                     {session: self.neo4j_session}.merge(options))
          end

          def #{name}(node = nil, rel = nil, query_proxy = nil)
            context = (query_proxy && query_proxy.context ? query_proxy.context : '#{self.name}') + '##{name}'
            #{name}_query_proxy(query_proxy: query_proxy, node: node, rel: rel, context: context)
          end}, __FILE__, __LINE__)
      end
      # rubocop:enable Style/PredicateName

      private

      def build_association(macro, direction, name, options)
        Neo4j::ActiveNode::HasN::Association.new(macro, direction, name, options).tap do |association|
          @associations ||= {}
          @associations[name] = association
          create_reflection(macro, name, association, self)
        end
      end
    end
  end
end
