module Neo4j
  module ActiveNode
    extend Forwardable
#    def_delegator :_unwrapped_node, :neo_id

    def self.included(klazz)
      # Active Attribute
      klazz.send(:include, ActiveAttr::MassAssignment)
      klazz.send(:include, ActiveAttr::TypecastedAttributes)

      klazz.send(:include, Neo4j::ActiveNode::Initialize)
      klazz.send(:include, Neo4j::ActiveNode::Persistence)
      klazz.extend(Neo4j::ActiveNode::Persistence::ClassMethods)
      klazz.send(:include, Neo4j::ActiveNode::Labels)
      klazz.extend(Neo4j::ActiveNode::Labels::ClassMethods)

      klazz.send(:include, Neo4j::EntityEquality)
      klazz.send(:include, Neo4j::ActiveNode::Callbacks)

      klazz.send(:include, ActiveModel::Validations)
      klazz.send(:include, Neo4j::ActiveNode::Validations)


      # Active Model, todo add more
      klazz.send(:include, ActiveModel::Conversion)

      # We overwrite the active_attr [] and []= methods here
      klazz.send(:include, Neo4j::ActiveNode::Properties)
    end

  end
end