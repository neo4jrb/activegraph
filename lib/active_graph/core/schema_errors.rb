module ActiveGraph
  module Core
    module SchemaErrors
      class ConstraintValidationFailedError < CypherError;
      end
      class ConstraintAlreadyExistsError < CypherError;
      end
      class IndexAlreadyExistsError < CypherError;
      end
    end
  end
end
