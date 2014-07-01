module Neo4j
  module ActiveNode
    # An abstraction layer to quickly build and return objects from the Neo4j Core Query class.
    # It auto-increments node and relationship identifiers, uses relationships pre-defined in models to create match methods, and automatically maps
    # results to collections.
    class QuickQuery
      attr_reader :quick_query

      # Initialize sets the values of @node_on_deck and defines @rel_on_deck, among other things.
      # The objects on deck are the objects implicitly modified when calling a method without specifying an identifier.
      # They are auto-incremented at stages throughout the class.
      def initialize(caller, as, caller_class = nil)
        @caller_class = caller_class || caller
        @node_on_deck = @return_obj = as
        @current_node_index = 2
        @current_rel_index = 1
        @rel_on_deck = nil
        @caller = caller
        @quick_query = caller.query_as(as)
        set_rel_methods(@caller_class)
        return self
      end

      # sends the #to_cypher method to the core query class 
      def to_cypher
        @quick_query.return(@return_obj).to_cypher
      end

      # Pass it a string or symbol to specify the target identifier.
      # Pass a hash to specify match parameters.
      # If an identifier is not specified, it will apply them to the on-deck node.
      # @example
      #     Student.qq.where(name: 'chris')
      #     Student.qq.lessons.where(:n2, name: 'history 101')
      def where(*args)
        target = args.select{|el| el.is_a?(String) || el.is_a?(Symbol) }
        send_target = target.empty? ? @node_on_deck : target.first
        result = process_args(args, send_target)
        @quick_query = @quick_query.where(result)
        return self
      end

      # Sends #return to the core query class, then maps the results to an enumerable.
      # This works because it assumes all returned objects will be of the same type.
      # Assumes the @return_obj if nothing is specified.
      # if you want distinct, pass 'true' as second parameter
      # @example
      #    Student.qq.lessons.return(:n2)
      #    Student.qq.lessons.return(:n2, true)
      def return(obj_sym = @return_obj, distinct = false)
        distinct ? r = "distinct #{obj_sym.to_s}" : r = obj_sym
        @quick_query.return(r).to_a.map{|el| el[obj_sym.to_sym]}
      end

      # Same as return but uses the existing @return_obj
      def to_a
        @quick_query.return(@return_obj).to_a.map{|el| el[@return_obj.to_sym]}
      end

      private

      # Creates match methods based on the caller's relationships defined in the model.
      # It works best when a relationship is defined explicitly with a direction and a receiving/incoming model.
      # This fires once on initialize, again every time a matcher method is called to build methods for the next step.
      # The dynamic classes accept the following:
      #    -a symbol or string to refer to the destination node
      #    -a hash with key :rel_as, value a string or symbol to act as relationship identifier (otherwise it uses r#{@current_rel_index})
      #    -a hash with key :rel_where containing other hashes of {parameter: value} to specify relationship conditions
      #    -hashes of {parameter: value} that specify conditions for the destination nodes
      # @example
      #   Student.qq.lessons
      #   Student.qq.lessons(rel_as: :student_status)
      #   Student.qq.lessons(rel_as: :student_status, rel_where: { grade: 'b-' })
      #   Student.qq.lessons(rel_as: :student_status, rel_where: { grade: 'b-' }, :lessinzzz, class: 'history 101').teachers
      def set_rel_methods(caller_class)
        caller_class._decl_rels.each { |k,v|
          if v.target_class.nil?
            class_eval(%Q{
              def #{k}(*args)
                process_rel(args, "#{v.rel_type}")
                return self
              end}, __FILE__, __LINE__)
          else
            class_eval(%Q{
              def #{k}(*args)
                process_rel(args, "#{v.rel_type}", "#{v.target_class.name}")
                return self
              end}, __FILE__, __LINE__)
          end
        }
      end

      # Called when a matcher method is called
      # args are the arguments sent along with the matcher method
      # rel_type is the defined relationship type
      # right_label is the label to use for the destination, if available. It's the "right label" cause it's on the right side... get it?
      # A label can only be used if the model defines the destination class explicitly.
      def process_rel(args, rel_type, right_label = nil)
        from_node = @node_on_deck
        hashes = args.select{|el| el.is_a?(Hash) }.first
        node_as = args.select{|el| el.is_a?(String) || el.is_a?(Symbol) }.first
        @node_on_deck = node_as.nil? ? new_node_id : node_as.to_sym
        @rel_on_deck = new_rel_id

        unless hashes.nil?
          @rel_on_deck = set_rel_as(hashes)
          set_rel_where(hashes)

          hashes.delete_if{|k,v| k == :rel_as || k == :rel_where }
          end_args = process_args([hashes], @node_on_deck) unless hashes.empty?
        end

        right_label.nil? ? destination = @node_on_deck : destination = "(#{@node_on_deck}:#{right_label})"
        @quick_query = @quick_query.match("#{from_node}-[#{@rel_on_deck}:`#{rel_type}`]-#{destination}")
        @quick_query = @quick_query.where(end_args) unless end_args.nil?
        set_rel_methods(right_label.constantize) unless right_label.nil?

        return self
      end

      def new_node_id
        n = "n#{@current_node_index}"
        @current_node_index += 1
        return n
      end

      def new_rel_id
        r = "r#{@current_rel_index}" 
        @current_rel_index += 1
        return r
      end

      def set_rel_as(h)
        h.has_key?(:rel_as) ? h[:rel_as] : new_rel_id
      end

      def set_rel_where(h)
        if h.has_key?(:rel_where)
          @quick_query = @quick_query.where(Hash[@rel_on_deck => h[:rel_where]])
        end
      end

      def process_args(args, where_target)
        end_args = []
        args.each do |arg|
          case arg
          when String, Symbol
            @node_on_deck = arg.to_s
            @return_obj = arg.to_s if @return_obj.nil?
          when Hash
            end_args.push Hash[where_target => arg]
          end
        end
        return end_args
      end
    end
  end
end
