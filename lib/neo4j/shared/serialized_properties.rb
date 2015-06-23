module Neo4j::Shared
  # This module adds the `serialize` class method. It lets you store hashes and arrays in Neo4j properties.
  # Be aware that you won't be able to search within serialized properties and stuff use indexes. If you do a regex search for portion of a string
  # property, the search happens in Cypher and you may take a performance hit.
  #
  # See type_converters.rb for the serialization process.
  module SerializedProperties
    extend ActiveSupport::Concern

    def serialized_properties
      self.class.serialized_properties
    end

    def serializable_hash(*args)
      super.merge(id: id)
    end


    module ClassMethods
      def inherited(other)
        inherit_serialized_properties(other) if self.respond_to?(:serialized_properties)
        super
      end

      def inherit_serialized_properties(other)
        other.serialized_properties = self.serialized_properties
      end
    end
  end
end
