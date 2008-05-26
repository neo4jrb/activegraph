include Java

module Neo4j
  require 'neo4j/neo-1.0-b6.jar'
  require 'neo4j/jta-spec1_0_1.jar'
  require 'neo4j/index-util-0.4-20080512.110337-6.jar'
  require 'neo4j/lucene-core-2.3.2.jar'
  
  EmbeddedNeo = org.neo4j.api.core.EmbeddedNeo
  StopEvaluator = org.neo4j.api.core.StopEvaluator
  Traverser = org.neo4j.api.core.Traverser
  ReturnableEvaluator = org.neo4j.api.core.ReturnableEvaluator
  Direction = org.neo4j.api.core.Direction
  IndexService = org.neo4j.util.index.IndexService

end