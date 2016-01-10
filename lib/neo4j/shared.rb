module Neo4j
  module Shared
    extend ActiveSupport::Concern
    extend ActiveModel::Naming

    include ActiveModel::Conversion
    include ActiveModel::Serializers::Xml
    include ActiveModel::Serializers::JSON

    module ClassMethods
      # TODO: Deprecate neo4j_session_name(name)
      def neo4j_session
        Neo4j::ActiveBase.current_session
      end

      def current_transaction
        Neo4j::ActiveBase.current_transaction
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
  end
end
