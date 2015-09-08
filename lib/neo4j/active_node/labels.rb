module Neo4j
  module ActiveNode
    # Provides a mapping between neo4j labels and Ruby classes
    module Labels
      extend ActiveSupport::Concern
      include Neo4j::ActiveNode::Labels::Reloading

      WRAPPED_CLASSES = []
      MODELS_FOR_LABELS_CACHE = {}
      MODELS_FOR_LABELS_CACHE.clear

      included do |model|
        def self.inherited(model)
          add_wrapped_class(model)

          super
        end

        Neo4j::ActiveNode::Labels.add_wrapped_class(model) unless Neo4j::ActiveNode::Labels._wrapped_classes.include?(model)
      end

      class InvalidQueryError < StandardError; end
      class RecordNotFound < StandardError; end

      # @return the labels
      # @see Neo4j-core
      def labels
        @_persisted_obj.labels
      end

      # this is handled by core, leaving it now for posterity
      # def queried_labels
      #   self.class.query_as(:result).where("ID(result)" => self.neo_id).return("LABELS(result) as result_labels").first.result_labels.map(&:to_sym)
      # end

      # adds one or more labels
      # @see Neo4j-core
      def add_label(*label)
        @_persisted_obj.add_label(*label)
      end

      # Removes one or more labels
      # Be careful, don't remove the label representing the Ruby class.
      # @see Neo4j-core
      def remove_label(*label)
        @_persisted_obj.remove_label(*label)
      end

      def self.add_wrapped_class(model)
        _wrapped_classes << model
      end

      def self._wrapped_classes
        Neo4j::ActiveNode::Labels::WRAPPED_CLASSES
      end

      def self.model_for_labels(labels)
        MODELS_FOR_LABELS_CACHE[labels] || model_cache(labels)
      end

      def self.model_cache(labels)
        models = WRAPPED_CLASSES.select do |model|
          (model.mapped_label_names - labels).size == 0
        end

        MODELS_FOR_LABELS_CACHE[labels] = models.max do |model|
          (model.mapped_label_names & labels).size
        end
      end

      def self.clear_model_for_label_cache
        MODELS_FOR_LABELS_CACHE.clear
      end

      def self.clear_wrapped_models
        WRAPPED_CLASSES.clear
      end

      module ClassMethods
        include Neo4j::ActiveNode::QueryMethods

        # Returns the object with the specified neo4j id.
        # @param [String,Integer] id of node to find
        def find(id)
          map_id = proc { |object| object.respond_to?(:id) ? object.send(:id) : object }

          result = if id.is_a?(Array)
                     find_by_ids(id.map { |o| map_id.call(o) })
                   else
                     find_by_id(map_id.call(id))
                   end
          fail Neo4j::RecordNotFound if result.blank?
          result
        end

        # Finds the first record matching the specified conditions. There is no implied ordering so if order matters, you should specify it yourself.
        # @param values Hash args of arguments to find
        def find_by(values)
          all.where(values).limit(1).query_as(:n).pluck(:n).first
        end

        # Like find_by, except that if no record is found, raises a RecordNotFound error.
        def find_by!(values)
          find_by(values) || fail(RecordNotFound, "#{self.query_as(:n).where(n: values).limit(1).to_cypher} returned no results")
        end

        # Deletes all nodes and connected relationships from Cypher.
        def delete_all
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) OPTIONAL MATCH n-[r]-() DELETE n,r")
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) DELETE n")
        end

        # Returns each node to Ruby and calls `destroy`. Be careful, as this can be a very slow operation if you have many nodes. It will generate at least
        # one database query per node in the database, more if callbacks require them.
        def destroy_all
          all.each(&:destroy)
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
            drop_constraint(property, type: :unique) if Neo4j::Label.constraint?(mapped_label_name, property)
            _index(property, conf)
          end
          indexed_properties.push property unless indexed_properties.include? property
        end

        # Creates a neo4j constraint on this class for given property
        #
        # @example
        #   Person.constraint :name, type: :unique
        #
        def constraint(property, constraints)
          Neo4j::Session.on_session_available do |session|
            unless Neo4j::Label.constraint?(mapped_label_name, property)
              label = Neo4j::Label.create(mapped_label_name)
              drop_index(property, label) if index?(property)
              label.create_constraint(property, constraints, session)
            end
          end
        end

        # @param [Symbol] property The name of the property index to be dropped
        # @param [Neo4j::Label] label An instance of label from Neo4j::Core
        def drop_index(property, label = nil)
          label_obj = label || Neo4j::Label.create(mapped_label_name)
          label_obj.drop_index(property)
        end

        # @param [Symbol] property The name of the property constraint to be dropped
        # @param [Hash] constraint The constraint type to be dropped.
        def drop_constraint(property, constraint = {type: :unique})
          Neo4j::Session.on_session_available do |session|
            label = Neo4j::Label.create(mapped_label_name)
            label.drop_constraint(property, constraint, session)
          end
        end

        def index?(index_def)
          mapped_label.indexes[:property_keys].include?([index_def])
        end

        # @return [Array{Symbol}] all the labels that this class has
        def mapped_label_names
          self.ancestors.find_all { |a| a.respond_to?(:mapped_label_name) }.map { |a| a.mapped_label_name.to_sym }
        end

        # @return [Symbol] the label that this class has which corresponds to a Ruby class
        def mapped_label_name
          @mapped_label_name || label_for_model
        end

        # @return [Neo4j::Label] the label for this class
        def mapped_label
          Neo4j::Label.create(mapped_label_name)
        end

        def indexed_properties
          @_indexed_properties ||= []
        end

        def base_class
          unless self < Neo4j::ActiveNode
            fail "#{name} doesn't belong in a hierarchy descending from ActiveNode"
          end

          if superclass == Object
            self
          else
            superclass.base_class
          end
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
          mapped_label_names.map { |label_name| Neo4j::Label.create(label_name) }
        end

        def mapped_label_name=(name)
          @mapped_label_name = name.to_sym
        end

        # rubocop:disable Style/AccessorMethodName
        def set_mapped_label_name(name)
          ActiveSupport::Deprecation.warn 'set_mapped_label_name is deprecated, use self.mapped_label_name= instead.', caller

          self.mapped_label_name = name
        end
        # rubocop:enable Style/AccessorMethodName

        private

        def label_for_model
          (self.name.nil? ? object_id.to_s.to_sym : decorated_label_name)
        end

        def decorated_label_name
          name =  case Neo4j::Config[:module_handling]
                  when :demodulize
                    self.name.demodulize
                  when Proc
                    Neo4j::Config[:module_handling].call self.name
                  else
                    self.name
                  end

          name.to_sym
        end
      end
    end
  end
end
