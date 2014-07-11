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
        @node_on_deck = @return_obj = as.to_sym
        @current_node_index = 2
        @current_rel_index = 1
        @rel_on_deck = nil
        @return_set = false
        @caller = caller
        @quick_query = caller.query_as(as)
        @identifiers = [@node_on_deck]
        set_rel_methods(@caller_class)
        return self
      end

      # sends the #to_cypher method to the core query class 
      def to_cypher
        @quick_query.return(@return_obj).to_cypher
      end


      # Creates methods that send cleaned up arguments to the Core Query class
      # Pass a symbol to specify the target identifier.
      # Pass a hash to specify match parameters.
      # Pass a valid cypher string to send directly to Core Query.
      # If an identifier is not specified, it will apply them to the on-deck node.
      # @example
      #     Student.qq.where(name: 'chris')
      #     Student.qq.lessons.where(:n2, name: 'history 101')
      #     Student.qq.lessons()
      CUSTOM_METHODS = %w[where set set_props]

      CUSTOM_METHODS.each do |method|
        class_eval(%Q{
          def #{method}(*args)
            result = prepare(args)
            final_query(__method__, result)
            return self
          end
        }, __FILE__, __LINE__)
      end


      # Creates methods that send strings directly to Core Query class
      LITERAL_METHODS = %w[limit skip match offset]

      LITERAL_METHODS.each do |method|
        class_eval(%Q{
          def #{method}(s)
            @quick_query = @quick_query.send(__method__, s)
            return self
          end
          }, __FILE__, __LINE__)
      end

      # Sends #return to the core query class, does not map to an enumerable.
      # Assumes the @return_obj if nothing is specified.
      # if you want distinct, pass boolean true
      # @example
      #    Student.qq.lessons.return(:n2)
      #    Student.qq.lessons.return(:n2, true)
      def return(*args)
        obj_sym = args.select{|el| el.is_a?(Symbol) }.first || @return_obj
        distinct = args.select{|el| el.is_a?(TrueClass) }.first || false
        
        r = final_return(obj_sym, distinct)
        @quick_query = @quick_query.return(r)
        return self
      end

      # Returns an enumerable of the query. If return has not been set, will set it to the on_deck node
      def to_a(distinct = false)
        @return_set ? result : self.return(distinct).to_a
      end

      # Same as to_a but with distinct set true
      def to_a!
        self.to_a(true)
      end

      # Set order for return.
      # @param prop_sym [Symbol] a symbol matching the property on the return class use for order
      # @param desc_bool [Boolean] boolean to dictate whether to sort descending. Defaults false, use true to descend
      def order(prop_sym, desc_bool = false)
        arg = "#{@return_obj}.#{prop_sym.to_s}"
        end_arg = desc_bool ? arg + ' DESC' : arg
        @quick_query = @quick_query.order(end_arg)
        return self
      end

      private

      def prepare(args)
        target = args.select{|el| el.is_a?(Symbol) }
        send_target = target.empty? ? @node_on_deck : target.first
        result = process_args(args, send_target)
      end

      def result
        response = @quick_query.response
        if response.is_a?(Neo4j::Server::CypherResponse)
          Neo4j::Session.current.search_result_to_enumerable_first_column(response)
        else
          Neo4j::Embedded::ResultWrapper.new(response, @quick_query.to_cypher).map{|x| x[0] }
        end
      end

      def final_return(return_obj, distinct)
        @return_set = true
        distinct ? "distinct #{return_obj.to_s}" : return_obj.to_sym
      end

      def final_query(method, result)
        @quick_query = @quick_query.send(method, result)
      end

      # Creates match methods based on the caller's relationships defined in the model.
      # It works best when a relationship is defined explicitly with a direction and a receiving/incoming model.
      # This fires once on initialize, again every time a matcher method is called to build methods for the next step.
      # The dynamic classes accept the following:
      #    -a symbol to refer to the destination node
      #    -a hash with key :rel_as, value a symbol to act as relationship identifier (otherwise it uses r#{@current_rel_index})
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
        hashes, strings = setup_rel_args(args)
        set_on_deck(args)

        hashes = process_rel_hashes(hashes) unless hashes.nil?
        end_args = process_args([hashes] + strings, @node_on_deck) unless hashes.nil? && strings.nil?

        destination = right_label.nil? ? @node_on_deck : "(#{@node_on_deck}:#{right_label})"
        @quick_query = @quick_query.match("#{from_node}-[#{@rel_on_deck}:`#{rel_type}`]-#{destination}")
        @quick_query = @quick_query.where(end_args) unless end_args.nil?
        set_rel_methods(right_label.constantize) unless right_label.nil?

        return self
      end

      # Prepares arguments passed with the relationship matcher. It finds hashes, which contain properties and values, and strings, which
      # which literal cypher phrases. 
      def setup_rel_args(args)
        hashes = args.select{|el| el.is_a?(Hash) }.first
        strings = args.select{|el| el.is_a?(String) }
        return hashes, strings
      end

      # Queues up the new node and relationship. This is only used during process_rel.
      def set_on_deck(args)
        @node_on_deck = @return_obj = node_as(args.select{|el| el.is_a?(Symbol) }.first)
        @rel_on_deck = new_rel_id
        @identifiers.push([@node_on_deck, @rel_on_deck])
      end

      # Prepares relationship-specific hashes found during the setup_rel_args method. Removes anything it finds from the hash and sends it back.
      def process_rel_hashes(hashes)
        @rel_on_deck = set_rel_as(hashes)
        @identifiers.push @rel_on_deck

        set_rel_where(hashes)

        hashes.delete_if{|k,v| k == :rel_as || k == :rel_where }
      end

      # Creates a new node identifier
      def new_node_id
        n = "n#{@current_node_index}"
        @current_node_index += 1
        return n
      end

      # Creates a new relationship identifier
      def new_rel_id
        r = "r#{@current_rel_index}" 
        @current_rel_index += 1
        return r
      end

      def node_as(node_as)
        node_as.nil? ? new_node_id : node_as.to_sym
      end

      def set_rel_as(h)
        h.has_key?(:rel_as) ? h[:rel_as] : new_rel_id
      end

      def set_rel_where(h)
        if h.has_key?(:rel_where)
          @quick_query = @quick_query.where(Hash[@rel_on_deck => h[:rel_where]])
        end
      end

      # Utility method used to split up passed values and fix syntax to match Neo4j Core Query class
      def process_args(args, where_target)
        end_args = []
        args.each do |arg|
          if arg.is_a?(String)
            end_args.push process_string(arg, where_target)
          elsif arg.is_a?(Symbol)
            @node_on_deck = arg
            @return_obj = arg if @return_obj.nil?
          elsif arg.is_a?(Hash)
            end_args.push Hash[where_target => arg] unless arg.empty?
          end
        end
        return end_args
      end

      # Attempts to determine whether the passed string already contains a node/rel identifier or if it needs one prepended.
      def process_string(arg, where_target)
        @identifiers.include?(arg.split('.').first.to_sym) ? arg : "#{where_target}.#{arg}"
      end
    end
  end
end
