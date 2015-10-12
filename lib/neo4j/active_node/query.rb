module Neo4j
  module ActiveNode
    # Helper methods to return Neo4j::Core::Query objects.  A query object can be used to successively build a cypher query
    #
    #    person.query_as(:n).match('n-[:friend]-o').return(o: :name) # Return the names of all the person's friends
    #
    module Query
      extend ActiveSupport::Concern

      # Returns a Query object with the current node matched the specified variable name
      #
      # @example Return the names of all of Mike's friends
      #   # Generates: MATCH (mike:Person), mike-[:friend]-friend WHERE ID(mike) = 123 RETURN friend.name
      #   mike.query_as(:mike).match('mike-[:friend]-friend').return(friend: :name)
      #
      # @param node_var [Symbol, String] The variable name to specify in the query
      # @return [Neo4j::Core::Query]
      def query_as(node_var)
        self.class.query_as(node_var, false).where("ID(#{node_var})" => self.neo_id)
      end

      # Starts a new QueryProxy with the starting identifier set to the given argument and QueryProxy source_object set to the node instance.
      # This method does not exist within QueryProxy and can only be used to start a new chain.
      #
      # @example Start a new QueryProxy chain with the first identifier set manually
      #   # Generates: MATCH (s:`Student`), (l:`Lesson`), s-[rel1:`ENROLLED_IN`]->(l:`Lesson`) WHERE ID(s) = {neo_id_17963}
      #   student.as(:s).lessons(:l)
      #
      # @param [String, Symbol] node_var The identifier to use within the QueryProxy object
      # @return [Neo4j::ActiveNode::Query::QueryProxy]
      def as(node_var)
        self.class.query_proxy(node: node_var, source_object: self).match_to(self)
      end

      module ClassMethods
        # Returns a Query object with all nodes for the model matched as the specified variable name
        #
        # @example Return the registration number of all cars owned by a person over the age of 30
        #   # Generates: MATCH (person:Person), person-[:owned]-car WHERE person.age > 30 RETURN car.registration_number
        #   Person.query_as(:person).where('person.age > 30').match('person-[:owned]-car').return(car: :registration_number)
        #
        # @param [Symbol, String] var The variable name to specify in the query
        # @param [Boolean] with_labels Should labels be used to build the match? There are situations (neo_id used to filter,
        # an early Cypher match has already filtered results) where including labels will degrade performance.
        # @return [Neo4j::Core::Query]
        def query_as(var, with_labels = true)
          query_proxy.query_as(var, with_labels)
        end

        Neo4j::ActiveNode::Query::QueryProxy::METHODS.each do |method|
          define_method(method) do |*args|
            self.query_proxy.send(method, *args)
          end
        end

        def query_proxy(options = {})
          Neo4j::ActiveNode::Query::QueryProxy.new(self, nil, options)
        end

        # Start a new QueryProxy with the starting identifier set to the given argument.
        # This method does not exist within QueryProxy, it can only be called at the class level to create a new QP object.
        # To set an identifier within a QueryProxy chain, give it as the first argument to a chained association.
        #
        # @example Start a new QueryProxy where the first identifier is set manually.
        #   # Generates: MATCH (s:`Student`), (result_lessons:`Lesson`), s-[rel1:`ENROLLED_IN`]->(result_lessons:`Lesson`)
        #   Student.as(:s).lessons
        #
        # @param [String, Symbol] node_var A string or symbol to use as the starting identifier.
        # @return [Neo4j::ActiveNode::Query::QueryProxy]
        def as(node_var)
          query_proxy(node: node_var, context: self.name)
        end
      end
    end
  end
end
