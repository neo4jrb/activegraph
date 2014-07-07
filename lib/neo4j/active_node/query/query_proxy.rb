module Neo4j
  module ActiveNode
    module Query

      class QueryProxy
        include Enumerable

        def initialize(model)
          @model = model
          @chain = []
        end

        def each
          query_as(:n).pluck(:n).each do |obj|
            yield obj
          end
        end

        METHODS = %w[where order skip limit]

        METHODS.each do |method|
          module_eval(%Q{
            def #{method}(*args)
              build_deeper_query_proxy(:#{method}, args)
            end}, __FILE__, __LINE__)
        end

        alias_method :offset, :skip
        alias_method :order_by, :order

        def query_as(var)
          query = @model.query_as(var).return(var)

          @chain.inject(query) do |query, (method, arg)|
            if arg.respond_to?(:call)
              query.send(method, arg.call(var))
            else
              query.send(method, arg)
            end
          end
        end

        def to_cypher
          query_as(:n).to_cypher
        end

        protected

        def add_links(links)
          @chain += links
        end

        private

        def build_deeper_query_proxy(method, args)
          self.dup.tap do |new_query|
          args.each do |arg|
            new_query.add_links(links_for_arg(method, arg))
          end
        end
      end

      def links_for_arg(method, arg)
        method_to_call = "links_for_#{method}_arg"

        default = [[method, arg]]

        self.send(method_to_call, arg) || default
      rescue NoMethodError
        default
      end

      def links_for_where_arg(arg)
        node_num = 1
        result = []
        if arg.is_a?(Hash)
          arg.map do |key, value|
            if @model.has_one_relationship?(key)
              neo_id = value.try(:neo_id) || value
              raise ArgumentError, "Invalid value for '#{key}' condition" if not neo_id.is_a?(Integer)

              n_string = "n#{node_num}"
              dir = @model.relationship_dir(key)

              arrow = dir == :outgoing ? '-->' : '<--'
              result << [:match, ->(v) { "#{v}#{arrow}(#{n_string})" }]
              result << [:where, ->(v) { {"ID(#{n_string})" => neo_id.to_i} }]
              node_num += 1
            else
              result << [:where, ->(v) { {v => {key => value}}}]
            end
          end
        end
        result
      end

      def links_for_order_arg(arg)
        [[:order, ->(v) { {v => arg} }]]
      end


      end

    end
  end
end

