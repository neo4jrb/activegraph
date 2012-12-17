module Neo4j
  module Rails
    module Identity

      def id
        _java_entity ? _java_entity.neo_id.to_s : nil
      end

      def neo_id
        _java_entity ? _java_entity.neo_id : nil
      end

      def getId
        new_record? ? nil : neo_id
      end

      def ==(other)
        new? ? self.__id__ == other.__id__ : super(other)
      end

    end
  end
end

