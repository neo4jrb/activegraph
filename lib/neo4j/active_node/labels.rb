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
        classes = @_wrapped_classes
        (class << klass
           self # the meta class
        end).send(:define_method, :inherited) do |klass|
          classes << klass
        end
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

        def all(session = Neo4j::Session.current)
          Neo4j::Label.find_all_nodes(mapped_label_name, session)
        end

        def count(session = Neo4j::Session.current)
          q = session.query("MATCH (n:`#{mapped_label_name}`) RETURN count(n) AS count")
          q.to_a[0][:count]
        end

        def find(key, value=nil, session = Neo4j::Session.current)
          if (value)
            Neo4j::Label.find_nodes(mapped_label_name, key, value, session)
          else
            Neo4j::Node.load(key)
          end
        end

        # Destroy all nodes an connected relationships
        def destroy_all
          Neo4j::Session.current._query("MATCH (n:`#{mapped_label_name}`)-[r]-() DELETE n,r")
          Neo4j::Session.current._query("MATCH (n:`#{mapped_label_name}`) DELETE n")
        end

        def index(property)
          if Neo4j::Session.current
            _index(property)
          else
            Neo4j::Session.add_listener do |event, _|
              _index(property) if event == :session_available
            end
          end
        end

        def _index(property)
          existing = mapped_label.indexes[:property_keys]
          # make sure the property is not indexed twice
          mapped_label.create_index(property) unless existing.flatten.include?(property)
        end

        def mapped_label_names
          self.ancestors.find_all { |a| a.respond_to?(:mapped_label_name) }.map { |a| a.mapped_label_name.to_sym }
        end

        def mapped_labels
          mapped_label_names.map{|label_name| Neo4j::Label.create(label_name)}
        end

        def mapped_label
          Neo4j::Label.create(mapped_label_name)
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