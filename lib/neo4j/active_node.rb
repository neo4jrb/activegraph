module Neo4j
  module ActiveNode
    extend ActiveSupport::Concern

    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::Serializers::Xml
    include ActiveModel::Serializers::JSON

    include Neo4j::ActiveNode::Initialize
    include Neo4j::ActiveNode::Identity
    include Neo4j::ActiveNode::Persistence
    include Neo4j::ActiveNode::Property
    include Neo4j::ActiveNode::Labels
    include Neo4j::ActiveNode::Callbacks
    include Neo4j::ActiveNode::Validations
  end
end