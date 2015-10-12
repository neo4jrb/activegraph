module Neo4j
  module Shared
    extend ActiveSupport::Concern
    extend ActiveModel::Naming

    include ActiveModel::Conversion
    include ActiveModel::Serializers::Xml
    include ActiveModel::Serializers::JSON

    module ClassMethods
      def neo4j_session
        Neo4j::Config[:session]
      end
    end

    included do
      self.include_root_in_json = Neo4j::Config.include_root_in_json
      @_declared_property_manager ||= Neo4j::Shared::DeclaredPropertyManager.new(self)

      def self.i18n_scope
        :neo4j
      end
    end

    def declared_property_manager
      self.class.declared_property_manager
    end
  end
end
