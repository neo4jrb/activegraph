include Java

module Neo4j
#  require 'neo4j/jars/neo-1.0-rc1-SNAPSHOT.jar'
#  require 'neo4j/jars/neo-1.0-b6.jar'
  require 'neo4j/jars/neo-1.0-rc1-20080612.151156-35.jar'
#  require 'neo4j/jars/neo-1.0-rc1-20080530.151028-34.jar'
  require 'neo4j/jars/jta-spec1_0_1.jar'

  EmbeddedNeo = org.neo4j.api.core.EmbeddedNeo
  StopEvaluator = org.neo4j.api.core.StopEvaluator
  Traverser = org.neo4j.api.core.Traverser
  ReturnableEvaluator = org.neo4j.api.core.ReturnableEvaluator
  Direction = org.neo4j.api.core.Direction

end