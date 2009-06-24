require 'rubygems'
require 'neo4j'
require 'neo4j/extensions/rest'
require 'neo4j/extensions/tx_tracker'

module Neo4j
  class TxNode
    include Neo4j::RestMixin
  end

  class TxRelationshipCreatedNode
    include Neo4j::RestMixin
  end

  class TxNodeCreated
    include Neo4j::RestMixin
  end

  class TxNodeList
    include Neo4j::RestMixin
  end

  class ReferenceNode
    include Neo4j::RestMixin
  end

end