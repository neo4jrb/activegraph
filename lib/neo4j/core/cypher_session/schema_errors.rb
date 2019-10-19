module Neo4j
  module Core
    class CypherSession
      module SchemaErrors
        class ConstraintValidationFailedError < CypherError; end
        class ConstraintAlreadyExistsError < CypherError; end
        class IndexAlreadyExistsError < CypherError; end
      end
    end
  end
end
