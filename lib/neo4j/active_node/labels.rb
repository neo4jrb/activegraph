module Neo4j
  module ActiveNode


    module Labels
      extend ActiveSupport::Concern

      def labels
        @_persisted_node.labels
      end

      def self.included(klass)
        @_wrapped_classes ||= []
        @_wrapped_classes << klass
      end

      def self._wrapped_classes
        @_wrapped_classes || []
      end

      # @private
      def self._wrapped_classes=(wrapped_classes)
        @_wrapped_classes=wrapped_classes
      end

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

        def find_all(session = Neo4j::Session.current)
          Neo4j::Label.find_all_nodes(mapped_label_name, session)
        end

        def find(key, value, session = Neo4j::Session.current)
          Neo4j::Label.find_nodes(mapped_label_name, key, value, session)
        end

        def index(property)
          mapped_label.create_index(property)
        end

        def mapped_label_names
          self.ancestors.find_all { |a| a.respond_to?(:mapped_label_name) }.map { |a| a.mapped_label_name.to_sym }
        end

        def mapped_labels
          mapped_label_names.map{|label_name| Neo4j::Label.create(label_name)}
        end

        def mapped_label
          @_label ||= Neo4j::Label.create(mapped_label_name)
        end

        def mapped_label_name
          @_label_name || self.to_s.to_sym
        end

        def set_mapped_label_name(name)
          @_label_name = name.to_sym
        end
      end

    end

  end
end