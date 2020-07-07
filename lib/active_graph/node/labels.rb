require 'active_graph/core/label'

module ActiveGraph
  module Node
    # Provides a mapping between neo4j labels and Ruby classes
    module Labels
      extend ActiveSupport::Concern
      include ActiveGraph::Node::Labels::Index
      include ActiveGraph::Node::Labels::Reloading

      WRAPPED_CLASSES = []
      MODELS_FOR_LABELS_CACHE = {}
      MODELS_FOR_LABELS_CACHE.clear

      included do |model|
        ActiveGraph::Node::Labels.clear_wrapped_models

        ActiveGraph::Node::Labels.add_wrapped_class(model) unless ActiveGraph::Node::Labels._wrapped_classes.include?(model)
      end

      class RecordNotFound < ActiveGraph::RecordNotFound; end

      # @return the labels
      # @see ActiveGraph::Core
      def labels
        @_persisted_obj.labels
      end

      # this is handled by core, leaving it now for posterity
      # def queried_labels
      #   self.class.query_as(:result).where("ID(result)" => self.neo_id).return("LABELS(result) as result_labels").first.result_labels.map(&:to_sym)
      # end

      # adds one or more labels
      # @see ActiveGraph::Core
      def add_labels(*labels)
        labels.inject(query_as(:n)) do |query, label|
          query.set("n:`#{label}`")
        end.exec
        @_persisted_obj.labels.concat(labels)
        @_persisted_obj.labels.uniq!
      end

      # Removes one or more labels
      # Be careful, don't remove the label representing the Ruby class.
      # @see ActiveGraph::Core
      def remove_labels(*labels)
        labels.inject(query_as(:n)) do |query, label|
          query.remove("n:`#{label}`")
        end.exec
        labels.each(&@_persisted_obj.labels.method(:delete))
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
        labels.sort!
        return MODELS_FOR_LABELS_CACHE[labels] if MODELS_FOR_LABELS_CACHE[labels]

        models = WRAPPED_CLASSES.select do |model|
          (model.mapped_label_names - labels).empty?
        end

        MODELS_FOR_LABELS_CACHE[labels] = models.max_by do |model|
          (model.mapped_label_names & labels).size
        end
      end

      def self.clear_wrapped_models
        MODELS_FOR_LABELS_CACHE.clear
        ActiveGraph::NodeWrapping::CONSTANTS_FOR_LABELS_CACHE.clear
      end

      module ClassMethods
        include ActiveGraph::Node::QueryMethods

        delegate :update_all, to: :all

        # Returns the object with the specified neo4j id.
        # @param [String,Integer] id of node to find
        def find(id)
          map_id = proc { |object| object.respond_to?(:id) ? object.send(:id) : object }

          result = find_by_id_or_ids(map_id, id)

          fail RecordNotFound.new(
            "Couldn't find #{name} with '#{id_property_name}'=#{id.inspect}",
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
          find_by(values) || fail(RecordNotFound.new("#{self.query_as(:n).where(n: values).limit(1).to_cypher} returned no results", name))
        end

        # Deletes all nodes and connected relationships from Cypher.
        def delete_all
          neo4j_query("MATCH (n:`#{mapped_label_name}`) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
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

        # @return [ActiveGraph::Label] the label for this class
        def mapped_label
          ActiveGraph::Core::Label.new(mapped_label_name)
        end

        def base_class
          unless self < ActiveGraph::Node
            fail "#{name} doesn't belong in a hierarchy descending from Node"
          end

          if superclass == Object
            self
          else
            superclass.base_class
          end
        end

        protected

        def mapped_labels
          mapped_label_names.map { |label_name| ActiveGraph::Label.create(label_name) }
        end

        def mapped_label_name=(name)
          @mapped_label_name = name.to_sym
        end

        # rubocop:disable Naming/AccessorMethodName
        def set_mapped_label_name(name)
          ActiveSupport::Deprecation.warn 'set_mapped_label_name is deprecated, use self.mapped_label_name= instead.', caller

          self.mapped_label_name = name
        end
        # rubocop:enable Naming/AccessorMethodName

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
          when ActiveGraph::Node
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
          name =  case ActiveGraph::Config[:module_handling]
                  when :demodulize
                    self.name.demodulize
                  when Proc
                    ActiveGraph::Config[:module_handling].call self.name
                  else
                    self.name
                  end

          name.to_sym
        end
      end
    end
  end
end
