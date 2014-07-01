module Neo4j
  module ActiveNode

    def qq(as = 'n1')
      QuickQuery.new(self, as, self.class)
    end

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
      # @param var [Symbol, String] The variable name to specify in the query
      # @return [Neo4j::Core::Query]
      def query_as(var)
        self.class.query_as(var).where("ID(#{var}) = #{self.neo_id}")
      end

      module ClassMethods
        # Returns a Query object with all nodes for the model matched as the specified variable name
        #
        # @example Return the registration number of all cars owned by a person over the age of 30
        #   # Generates: MATCH (person:Person), person-[:owned]-car WHERE person.age > 30 RETURN car.registration_number
        #   Person.query_as(:person).where('person.age > 30').match('person-[:owned]-car').return(car: :registration_number)
        #
        # @param var [Symbol, String] The variable name to specify in the query
        # @return [Neo4j::Core::Query]
        def query_as(var)
          Neo4j::Core::Query.new.match(var => self)
        end

        def qq(as = 'n1')
          QuickQuery.new(self.name.constantize, as)
        end
      end
    end
  end
end
