module Neo4j
  # Neo4j.rb Errors
  # Generic Neo4j.rb exception class.
  class Neo4jrbError < StandardError
  end

  # Raised when Neo4j.rb cannot find record by given id.
  class RecordNotFound < Neo4jrbError
    attr_reader :model, :primary_key, :id

    def initialize(message = nil, model = nil, primary_key = nil, id = nil)
      @primary_key = primary_key
      @model = model
      @id = id

      super(message)
    end
  end

  class InvalidPropertyOptionsError < Neo4jrbError
  end

  class InvalidParameterError < Neo4jrbError
  end
end
