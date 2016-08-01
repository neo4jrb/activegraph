module Neo4j
  module ActiveNode
    # Provides a mapping between neo4j labels and Ruby classes
    module Labels
      extend ActiveSupport::Concern
      include Neo4j::ActiveNode::Labels::Index
      include Neo4j::ActiveNode::Labels::Reloading

      WRAPPED_CLASSES = []
      MODELS_FOR_LABELS_CACHE = {}
      MODELS_FOR_LABELS_CACHE.clear

      included do |model|
        Neo4j::ActiveNode::Labels.clear_wrapped_models

        Neo4j::ActiveNode::Labels.add_wrapped_class(model) unless Neo4j::ActiveNode::Labels._wrapped_classes.include?(model)
      end

      class RecordNotFound < Neo4j::RecordNotFound; end

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

      def self._wrapped_classes
        WRAPPED_CLASSES
      end

      def self.add_wrapped_class(model)
        _wrapped_classes << model
      end

      # Finds an appropriate matching model given a set of labels
      # which are assigned to a node
      def self.model_for_labels(labels)
        return MODELS_FOR_LABELS_CACHE[labels] if MODELS_FOR_LABELS_CACHE[labels]

        models = WRAPPED_CLASSES.select do |model|
          (model.mapped_label_names - labels).size == 0
        end

        MODELS_FOR_LABELS_CACHE[labels] = models.max_by do |model|
          (model.mapped_label_names & labels).size
        end
      end

      def self.clear_wrapped_models
        MODELS_FOR_LABELS_CACHE.clear
        Neo4j::Node::Wrapper::CONSTANTS_FOR_LABELS_CACHE.clear
      end

      module ClassMethods
        include Neo4j::ActiveNode::QueryMethods

        delegate :update_all, to: :all

        # Returns the object with the specified neo4j id.
        # @param [String,Integer] id of node to find
        def find(id)
          map_id = proc { |object| object.respond_to?(:id) ? object.send(:id) : object }

          result = find_by_id_or_ids(map_id, id)

          fail RecordNotFound.new(
            "Couldn't find #{name} with '#{id_property_name}'=#{id}",
            name, id_property_name, id) if result.blank?
          result.tap { |r| find_callbacks!(r) }
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
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
          self.neo4j_session._query("MATCH (n:`#{mapped_label_name}`) DELETE n")
        end

        # Returns each node to Ruby and calls `destroy`. Be careful, as this can be a very slow operation if you have many nodes. It will generate at least
        # one database query per node in the database, more if callbacks require them.
        def destroy_all
          all.each(&:destroy)
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

        def find_by_id_or_ids(map_id, id)
          if id.is_a?(Array)
            find_by_ids(id.map(&map_id))
          else
            find_by_id(map_id.call(id))
          end
        end

        def find_callbacks!(result)
          case result
          when Neo4j::ActiveNode
            result.run_callbacks(:find)
          when Array
            result.each { |r| find_callbacks!(r) }
          else
            result
          end
        end

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
