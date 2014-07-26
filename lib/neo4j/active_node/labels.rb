module Neo4j
  module ActiveNode


    # Provides a mapping between neo4j labels and Ruby classes
    module Labels
      extend ActiveSupport::Concern

      WRAPPED_CLASSES = []
      class InvalidQueryError < StandardError; end
      class RecordNotFound < StandardError; end

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
        # Find all nodes/objects of this class
        def all
          self.query_as(:n).pluck(:n)
        end

        # Returns the first node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
        def first
          self.query_as(:n).limit(1).order('ID(n)').pluck(:n).first
        end

        # Returns the last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
        def last
          self.query_as(:n).order('ID(n) DESC').limit(1).pluck(:n).first
        end

        # @return [Fixnum] number of nodes of this class
        def count
          self.query_as(:n).return("count(n) AS count").first.count
        end

        # Returns the object with the specified neo4j id.
        # @param [String,Fixnum] id of node to find
        # @param [Neo4j::Session] session optional
        def find(id, session = self.neo4j_session)
          raise "Unknown argument #{id.class} in find method (expected String or Fixnum)" if not [String, Fixnum].include?(id.class)
          find_by_id(id, session)
        end

        # Finds the first record matching the specified conditions. There is no implied ordering so if order matters, you should specify it yourself.
        # @param [Hash] args of arguments to find
        def find_by(*args)
          self.query_as(:n).where(n: eval(args.join)).limit(1).pluck(:n).first
        end

        # Like find_by, except that if no record is found, raises a RecordNotFound error. 
        def find_by!(*args)
          a = eval(args.join)
          find_by(args) or raise RecordNotFound, "#{self.query_as(:n).where(n: a).limit(1).to_cypher} returned no results"
        end

        # Destroy all nodes and connected relationships
        def destroy_all
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`)-[r]-() DELETE n,r")
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) DELETE n")
        end

        # Creates a Neo4j index on given property
        #
        # This can also be done on the property directly, see Neo4j::ActiveNode::Property::ClassMethods#property.
        #
        # @param [Symbol] property the property we want a Neo4j index on
        # @param [Hash] conf optional property configuration
        #
        # @example
        #   class Person
        #      include Neo4j::ActiveNode
        #      property :name
        #      index :name
        #    end
        #
        # @example with constraint
        #   class Person
        #      include Neo4j::ActiveNode
        #      property :name
        #
        #      # below is same as: index :name, index: :exact, constraint: {type: :unique}
        #      index :name, constraint: {type: :unique}
        #    end
        def index(property, conf = {})
          Neo4j::Session.on_session_available do |_|
            _index(property, conf)
          end
          @_indexed_properties ||= []
          @_indexed_properties.push property unless @_indexed_properties.include? property
        end

        # Creates a neo4j constraint on this class for given property
        #
        # @example
        #   Person.constraint :name, type: :unique
        #
        def constraint(property, constraints, session = Neo4j::Session.current)
          Neo4j::Session.on_session_available do |_|
            label = Neo4j::Label.create(mapped_label_name)
            label.create_constraint(property, constraints, session)
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

        # @return [Neo4j::Label] the label for this class
        def mapped_label
          Neo4j::Label.create(mapped_label_name)
        end

        def indexed_properties
          @_indexed_properties
        end


        protected

        def _index(property, conf)
          mapped_labels.each do |label|
            # make sure the property is not indexed twice
            existing = label.indexes[:property_keys]

            # In neo4j constraint automatically creates an index
            if conf[:constraint]
              constraint(property, conf[:constraint])
            else
              label.create_index(property) unless existing.flatten.include?(property)
            end

          end
        end

        def mapped_labels
          mapped_label_names.map{|label_name| Neo4j::Label.create(label_name)}
        end

        def set_mapped_label_name(name)
          @_label_name = name.to_sym
        end

      end

    end

  end
end
