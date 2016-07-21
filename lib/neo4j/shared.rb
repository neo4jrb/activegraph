module Neo4j
  module Shared
    extend ActiveSupport::Concern
    extend ActiveModel::Naming

    include ActiveModel::Conversion
    begin
    include ActiveModel::Serializers::Xml
    rescue NameError; end # rubocop:disable Lint/HandleExceptions
    include ActiveModel::Serializers::JSON

    module ClassMethods
      # TODO: Deprecate neo4j_session_name(name)

      # remove?
      def neo4j_session
        Neo4j::ActiveBase.current_session
      end

      # remove?
      def current_transaction
        Neo4j::ActiveBase.current_transaction
      end

      # This should be used everywhere.  Should make it easy
      # to support a session-per-model system
      def neo4j_query(*args)
        Neo4j::ActiveBase.query(*args)
      end

      def new_query
        Neo4j::ActiveBase.new_query
      end
    end

    included do
      self.include_root_in_json = Neo4j::Config.include_root_in_json
      @_declared_properties ||= Neo4j::Shared::DeclaredProperties.new(self)

      def self.i18n_scope
        :neo4j
      end

      def self.inherited(other)
        attributes.each_pair do |k, v|
          other.inherit_property k.to_sym, v.clone, declared_properties[k].options
        end
        super
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
