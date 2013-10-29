require 'neo4j/version'


module Neo4j
  module ActiveModel
    class UnPersistedNode
      attr_reader :props

      def initialize(props)
        @props = props
      end
      def neo_id
        nil
      end

      def [](key)
        @props[key]
      end

      def []=(key,value)
        @props[key] = value
      end
    end

    def self.included(klazz)
      klazz.send(:include, Neo4j::Wrapper::NodeMixin)
      klazz.extend(ClassMethods)
    end


    def save
      init_on_load(Neo4j::Node.create(_unwrapped_node.props))
    end

    module ClassMethods
      def new(props={})
        super().tap do |node|
          node.init_on_load(UnPersistedNode.new(props))
        end
      end
    end
  end
end