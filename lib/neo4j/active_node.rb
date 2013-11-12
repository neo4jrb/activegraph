module Neo4j
  module ActiveNode
    extend Forwardable
#    def_delegator :_unwrapped_node, :neo_id

    def self.included(klazz)
      klazz.send(:include, Neo4j::ActiveNode::Initialize)
      klazz.send(:include, Neo4j::ActiveNode::Persistence)
      klazz.extend(Neo4j::ActiveNode::Persistence::ClassMethods)
      klazz.send(:include, Neo4j::ActiveNode::Labels)
      klazz.extend(Neo4j::ActiveNode::Labels::ClassMethods)

      klazz.send(:include, Neo4j::ActiveNode::Properties)

      klazz.send(:include, ::ActiveModel::Conversion)
      klazz.extend(ClassMethods)

      klazz.send(:include, Neo4j::EntityEquality)
      #klazz.extend(ActiveModel::Callbacks)

      # define_model_callbacks :initialize, :only => :after
      # define_model_callbacks :validation, :create, :save, :update, :destroy
    end



    module ClassMethods
      def new(props={})
        super().tap do |node|
          node.init_on_new(props)
        end
      end
    end
  end
end