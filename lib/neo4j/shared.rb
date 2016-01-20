module Neo4j
  module Shared
    extend ActiveSupport::Concern
    extend ActiveModel::Naming

    include ActiveModel::Conversion
    include ActiveModel::Serializers::Xml
    include ActiveModel::Serializers::JSON

    module ClassMethods
      # TODO: Deprecate neo4j_session_name(name)

      SelfDeprecation.:neo4j_session_name

      def neo4j_session
        Neo4j::ActiveBase.current_session
      end

      def current_transaction
        Neo4j::ActiveBase.current_transaction
      end

      def neo4j_current_transaction_or_session
        current_transaction || neo4j_session
      end

      # This should be used everywhere.  Should make it easy
      # to support a session-per-model system
      def neo4j_query(*args)
        puts 'querying...'
        neo4j_current_transaction_or_session.query(*args)
      end
    end

    included do
      self.include_root_in_json = Neo4j::Config.include_root_in_json
      @_declared_properties ||= Neo4j::Shared::DeclaredProperties.new(self)

      def self.i18n_scope
        :neo4j
      end
    end

    def declared_properties
      self.class.declared_properties
    end

    def neo4j_query(*args)
      self.class.neo4j_query(*args)
    end
  end
end
