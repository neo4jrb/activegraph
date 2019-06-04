module Neo4j
  module ActiveNode
    module Query
      # Methods related to returning nodes and rels from QueryProxy
      module QueryProxyEnumerable
        include Enumerable

        # Just like every other <tt>each</tt> but it allows for optional params to support the versions that also return relationships.
        # The <tt>node</tt> and <tt>rel</tt> params are typically used by those other methods but there's nothing stopping you from
        # using `your_node.each(true, true)` instead of `your_node.each_with_rel`.
        # @return [Enumerable] An enumerable containing some combination of nodes and rels.
        def each(node = true, rel = nil, &block)
          result(node, rel).each(&block)
        end

        def result(node = true, rel = nil)
          return [].freeze if unpersisted_start_object?

          @result_cache ||= {}
          return result_cache_for(node, rel) if result_cache?(node, rel)

          result = pluck_vars(node, rel)
          set_instance_caches(result, node, rel)

          @result_cache[[node, rel]] ||= result
        end

        def result_cache?(node = true, rel = nil)
          !!result_cache_for(node, rel)
        end

        def result_cache_for(node = true, rel = nil)
          (@result_cache || {})[[node, rel]]
        end

        def fetch_result_cache
          @result_cache ||= yield
        end

        # When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
        # For example, to return the relationship between a given student and their lessons:
        #
        # .. code-block:: ruby
        #
        #   student.lessons.each_rel do |rel|
        #
        # @return [Enumerable] An enumerable containing any number of applicable relationship objects.
        def each_rel(&block)
          block_given? ? each(false, true, &block) : to_enum(:each, false, true)
        end

        # When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
        # For example, to return a lesson and each relationship to a given student:
        #
        # .. code-block:: ruby
        #
        #   student.lessons.each_with_rel do |lesson, rel|
        def each_with_rel(&block)
          block_given? ? each(true, true, &block) : to_enum(:each, true, true)
        end

        # Does exactly what you would hope. Without it, comparing `bobby.lessons == sandy.lessons` would evaluate to false because it
        # would be comparing the QueryProxy objects, not the lessons themselves.
        def ==(other)
          self.to_a == other
        end

        # For getting variables which have been defined as part of the association chain
        def pluck(*args)
          transformable_attributes = (model ? model.attribute_names : []) + %w(uuid neo_id)
          arg_list = args.map do |arg|
            arg = Neo4j::ActiveNode::Query::QueryProxy::Link.converted_key(model, arg)
            if transformable_attributes.include?(arg.to_s)
              {identity => arg}
            else
              arg
            end
          end

          self.query.pluck(*arg_list)
        end

        protected

        def ensure_distinct(node, force = false)
          @distinct || force ? "DISTINCT(#{node})" : node
        end

        private

        def pluck_vars(node, rel)
          vars = []
          vars << ensure_distinct(identity) if node
          vars << @rel_var if rel
          pluck(*vars)
        end

        def set_instance_caches(instance, node, rel)
          instance.each do |object|
            object.instance_variable_set('@source_query_proxy', self)
            object.instance_variable_set('@source_proxy_result_cache', instance)
            if node && rel && object.last.is_a?(Neo4j::ActiveRel)
              object.last.instance_variable_set(association.direction == :in ? '@from_node' : '@to_node', object.first)
            end
          end
        end
      end
    end
  end
end
