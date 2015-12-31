module Neo4j::Shared
  module Typecasting
    # This exception is raised if attempting to cast to an unknown type when
    # using {Typecasting}
    #
    # @since 0.6.0
    class UnknownTypecasterError < TypeError
    end
  end
end
