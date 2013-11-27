module Neo4j
  module ActiveNode
    extend ActiveSupport::Concern
#    def_delegator :_unwrapped_node, :neo_id

    include ActiveAttr::MassAssignment
    include ActiveAttr::TypecastedAttributes

    include Neo4j::EntityEquality

    include Neo4j::ActiveNode::Initialize
    include Neo4j::ActiveNode::Persistence
    include Neo4j::ActiveNode::Properties
    include Neo4j::ActiveNode::Labels
    include Neo4j::ActiveNode::Callbacks
    include Neo4j::ActiveNode::Validations

    # TODO add more active model support
    include ActiveModel::Validations
    include ActiveModel::Conversion

    def self.included42(klazz)
      # Active Attribute
      #klazz.send(:include, ActiveAttr::MassAssignment)
      #klazz.send(:include, ActiveAttr::TypecastedAttributes)

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
      #klazz.send(:include, Neo4j::ActiveNode::Properties)

      #klazz.send(:alias_method, :props, :attributes)
    end


  end
end