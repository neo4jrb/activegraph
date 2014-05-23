module Neo4j
  module ActiveNode


    # Provides a mapping between neo4j labels and Ruby classes
    module Labels
      extend ActiveSupport::Concern

      WRAPPED_CLASSES = []
      class InvalidQueryError < StandardError; end

      # @return the labels
      # @see Neo4j-core
      def labels
        @_persisted_node.labels
      end

      # adds one or more labels
      # @see Neo4j-core
      def add_label(*label)
        @_persisted_node.add_label(*label)
      end

      # Removes one or more labels
      # Be careful, don't remove the label representing the Ruby class.
      # @see Neo4j-core
      def remove_label(*label)
        @_persisted_node.remove_label(*label)
      end

      def self.included(klass)
        add_wrapped_class(klass)
      end

      def self.add_wrapped_class(klass)
        _wrapped_classes << klass
        @_wrapped_labels = nil
      end

      def self._wrapped_classes
        Neo4j::ActiveNode::Labels::WRAPPED_CLASSES
      end

      protected

      # Only for testing purpose
      # @private
      def self._wrapped_labels=(wl)
        @_wrapped_labels=(wl)
      end

      def self._wrapped_labels
        @_wrapped_labels ||=  _wrapped_classes.inject({}) do |ack, clazz|
          ack.tap do |a|
            a[clazz.mapped_label_name.to_sym] = clazz if clazz.respond_to?(:mapped_label_name)
          end
        end
      end

      module ClassMethods

        # Find all nodes/objects of this class, with given search criteria
        # @param [Hash, nil] args the search critera or nil if finding all
        # @param [Neo4j::Session] session defaults to the model's session
        def all(args = nil, session = self.neo4j_session)
          if args
            find_by_hash(args, session)
          else
            Neo4j::Label.find_all_nodes(mapped_label_name, session)
          end
        end

        # @return [Fixnum] number of nodes of this class
        def count(session = self.neo4j_session)
          q = session.query("MATCH (n:`#{mapped_label_name}`) RETURN count(n) AS count")
          q.to_a[0][:count]
        end

        # Same as #all but return only one object
        # If given a String or Fixnum it will return the object with that neo4j id.
        # @param [Hash,String,Fixnum] args search criteria
        def find(args, session = self.neo4j_session)
          case args
            when Hash
              find_by_hash(args, session).first
            when String, Fixnum
              Neo4j::Node.load(args.to_i)
            else
              raise "Unknown argument #{args.class} in find method"
          end
        end


        # Destroy all nodes an connected relationships
        def destroy_all
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`)-[r]-() DELETE n,r")
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) DELETE n")
        end

        # Creates a Neo4j index on given property
        # @param [Symbol] property the property we want a Neo4j index on
        def index(property)
          if self.neo4j_session
            _index(property)
          else
            Neo4j::Session.add_listener do |event, _|
              _index(property) if event == :session_available
            end
          end
        end

        def index?(index_def)
          mapped_label.indexes[:property_keys].include?(index_def)
        end

        # @return [Array{Symbol}] all the labels that this class has
        def mapped_label_names
          self.ancestors.find_all { |a| a.respond_to?(:mapped_label_name) }.map { |a| a.mapped_label_name.to_sym }
        end

        # @return [Symbol] the label that this class has which corresponds to a Ruby class
        def mapped_label_name
          @_label_name || self.to_s.to_sym
        end

        def indexed_labels

        end

        protected

        def find_by_hash(query, session)
          validate_query!(query)

          extract_relationship_conditions!(query)

          Neo4j::Label.query(mapped_label_name, query, session)
        end

        # Raises an error if query is malformed
        def validate_query!(query)
          invalid_query_keys = query.keys.map(&:to_sym) - [:conditions, :order, :limit, :offset, :skip]

          raise InvalidQueryError, "Invalid query keys: #{invalid_query_keys.join(', ')}" if not invalid_query_keys.empty?
        end

        # Takes out :conditions query keys for associations and creates corresponding :conditions and :matches keys  
        # example:
        # class Person
        #   property :name
        #   has_n :friend
        # end
        #
        #   :conditions => {name: 'Fred', friend: person}
        # should result in:
        #   :conditions => {name => 'Fred', 'id(n1)' => person.id}, :matches => 'n--n1'
        #
        def extract_relationship_conditions!(query)
          node_num = 1
          if query[:conditions]
            query[:conditions].dup.each do |key, value|
              if has_relationship?(key)
                neo_id = value.try(:neo_id) || value
                raise InvalidQueryError, "Invalid value for '#{key}' condition" if not neo_id.is_a?(Integer)

                query[:matches] ||= []
                n_string = "n#{node_num}"
                query[:matches] << "n--(#{n_string})"
                query[:conditions]["id(#{n_string})"] = neo_id
                query[:conditions].delete(key)
                node_num += 1
              end
            end
          end
        end

        def _index(property)
          mapped_labels.each do |label|
            # make sure the property is not indexed twice
            existing = label.indexes[:property_keys]
            label.create_index(property) unless existing.flatten.include?(property)
          end
        end

        def mapped_labels
          mapped_label_names.map{|label_name| Neo4j::Label.create(label_name)}
        end

        def mapped_label
          Neo4j::Label.create(mapped_label_name)
        end

        def set_mapped_label_name(name)
          @_label_name = name.to_sym
        end

      end

    end

  end
end
