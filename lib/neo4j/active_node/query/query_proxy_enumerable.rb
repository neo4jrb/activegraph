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
          pluck_vars = []
          pluck_vars << identity if node
          pluck_vars << @rel_var if rel

          pluck(*pluck_vars).each(&block)
        end

        def with_associations(*spec)
          query = self.query_as(:previous).return(:previous)

          spec.each do |association_name|
            association = @model.associations[association_name]
            query = query.optional_match("previous#{association.arrow_cypher}#{association_name}")
          end

          return_object_clause = '[' + spec.map { |n| "collect(#{n})" }.join(',') + ']'
          query.pluck(:previous, return_object_clause).map do |record, eager_data|
            record.tap do |record|
              eager_data.each_with_index do |eager_records, index|
                record.send(spec[index]).cache_result(eager_records)
              end
            end
          end
        end

        # When called at the end of a QueryProxy chain, it will return the resultant relationship objects intead of nodes.
        # For example, to return the relationship between a given student and their lessons:
        #   student.lessons.each_rel do |rel|
        # @return [Enumerable] An enumerable containing any number of applicable relationship objects.
        def each_rel(&block)
          block_given? ? each(false, true, &block) : to_enum(:each, false, true)
        end

        # When called at the end of a QueryProxy chain, it will return the nodes and relationships of the last link.
        # For example, to return a lesson and each relationship to a given student:
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
            if transformable_attributes.include?(arg.to_s)
              {identity => arg}
            else
              arg
            end
          end

          self.query.pluck(*arg_list)
        end
      end
    end
  end
end
