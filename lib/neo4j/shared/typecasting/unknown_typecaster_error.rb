module Neo4j::Shared
  module Typecasting
    # This exception is raised if attempting to cast to an unknown type when
    # using {Typecasting}
    class UnknownTypecasterError < TypeError
    end
  end
end
