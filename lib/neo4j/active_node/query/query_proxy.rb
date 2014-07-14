module Neo4j
  module ActiveNode
    module Query

      class QueryProxy
        include Enumerable

        def initialize(model, association_options = nil)
          @model = model
          @association_options = association_options
          @chain = []
        end

        def each
          query_as(:result).pluck(:result).each do |obj|
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

        def pluck(var)
          self.query_as(:n).pluck(var)
        end

        def association_chain_var
          if start_object = @association_options[:start_object]
            :"#{start_object.class.name.downcase}#{start_object.neo_id}"
          elsif @association_options[:query_proxy]
            @chain_var_num = (@chain_var_num || 0) + 1
            :"node#{@chain_var_num}"
          else
            raise "Crazy error" # TODO: Better error
          end
        end

        def association_query_start(var)
          if start_object = @association_options[:start_object]
            start_object.query_as(var)
          elsif query_proxy = @association_options[:query_proxy]
            query_proxy.query_as(var)
          else
            raise "Crazy error" # TODO: Better error
          end
        end

        def query_as(var)
          query = if @association_options
            chain_var = association_chain_var
            (association_query_start(chain_var) & query_model_as(var)).match("#{chain_var}#{association_arrow}(#{var}:`#{@model.name}`)")
          else
            query_model_as(var)
          end

          @chain.inject(query) do |query, (method, arg)|
            if arg.respond_to?(:call)
              query.send(method, arg.call(var))
            else
              query.send(method, arg)
            end
          end
        end

        def query_model_as(var)
          label = @model.respond_to?(:mapped_label_name) ? @model.mapped_label_name : @model
          neo4j_session.query.match(var => label)
        end

        def to_cypher
          query_as(:n).to_cypher
        end

        def <<(other_node)
          if @association_options
            raise ArgumentError, "Node must be of the association's class" if other_node.class != @model

            association_query_start(:start)
              .match(end: other_node.class)
              .where(end: {neo_id: other_node.neo_id})
              .create("start#{association_arrow}end").exec
          else
            raise "Can only create associations on associations"
          end
        end

        def method_missing(method_name, *args)
          if @model.respond_to?(method_name)
            @model.query_proxy = self
            result = @model.send(method_name, *args)
            @model.query_proxy = nil
            result
          else
            super
          end
        end

        protected

        def add_links(links)
          @chain += links
        end

        private

        def association_arrow
          if @association_options
            relationship = (@association_options[:relationship] == false) ? '' : "[:#{@association_options[:relationship]}]"
            case direction = @association_options[:direction].to_sym
              when :outbound
                "-#{relationship}->"
              when :inbound
                "<-#{relationship}-"
              else
                raise ArgumentError, "Invalid relationship direction: #{direction}"
            end
          end
        end

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

