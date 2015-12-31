module Neo4j
  # Neo4j.rb Errors
  # Generic Neo4j.rb exception class.
  class Neo4jrbError < StandardError
  end

  # Raised when Neo4j.rb cannot find record by given id.
  class RecordNotFound < Neo4jrbError
  end

  class InvalidPropertyOptionsError < Neo4jrbError; end
  class DangerousAttributeError < ScriptError; end
  class UnknownAttributeError < NoMethodError; end
end
