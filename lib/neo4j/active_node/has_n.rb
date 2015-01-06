module Neo4j::ActiveNode
  module HasN
    extend ActiveSupport::Concern

    class NonPersistedNodeError < StandardError; end

    # Clears out the association cache.
    def clear_association_cache #:nodoc:
      association_cache.clear if _persisted_obj
    end

    # Returns the current association cache. It is in the format
    # { :association_name => { :hash_of_cypher_string => [collection] }}
    def association_cache
      @association_cache ||= {}
    end

    # Returns the specified association instance if it responds to :loaded?, nil otherwise.
    # @param [String] cypher_string the cypher, with params, used for lookup
    # @param [Enumerable] association_obj the HasN::Association object used to perform this query
    def association_instance_get(cypher_string, association_obj)
      return if association_cache.nil? || association_cache.empty?
      lookup_obj = cypher_hash(cypher_string)
      reflection = association_reflection(association_obj)
      return if reflection.nil?
      association_cache[reflection.name] ? association_cache[reflection.name][lookup_obj] : nil
    end

    # @return [Hash] A hash of all queries in @association_cache created from the association owning this reflection
    def association_instance_get_by_reflection(reflection_name)
      association_cache[reflection_name]
    end

    # Caches an association result. Unlike ActiveRecord, which stores results in @association_cache using { :association_name => [collection_result] },
    # ActiveNode stores it using { :association_name => { :hash_string_of_cypher => [collection_result] }}.
    # This is necessary because an association name by itself does not take into account :where, :limit, :order, etc,... so it's prone to error.
    # @param [Neo4j::ActiveNode::Query::QueryProxy] query_proxy The QueryProxy object that resulted in this result
    # @param [Enumerable] collection_result The result of the query after calling :each
    # @param [Neo4j::ActiveNode::HasN::Association] association_obj The association traversed to create the result
    def association_instance_set(cypher_string, collection_result, association_obj)
      return collection_result if Neo4j::Transaction.current
      cache_key = cypher_hash(cypher_string)
      reflection = association_reflection(association_obj)
      return if reflection.nil?
      if @association_cache[reflection.name]
        @association_cache[reflection.name][cache_key] = collection_result
      else
        @association_cache[reflection.name] = {cache_key => collection_result}
      end
      collection_result
    end

    def association_reflection(association_obj)
      self.class.reflect_on_association(association_obj.name)
    end

    # Uses the cypher generated by a QueryProxy object, complete with params, to generate a basic non-cryptographic hash
    # for use in @association_cache.
    # @param [String] the cypher used in the query
    # @return [String] A basic hash of the query
    def cypher_hash(cypher_string)
      cypher_string.hash.abs
    end

    module ClassMethods
      def has_association?(name)
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
