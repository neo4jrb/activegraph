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
      attr_writer :neo4j_session_name

      def neo4j_session_name(name)
        ActiveSupport::Deprecation.warn 'neo4j_session_name is deprecated and may be removed from future releases, use neo4j_session_name= instead.', caller

        @neo4j_session_name = name
      end

      def neo4j_session
        if @neo4j_session_name
          Neo4j::Session.named(@neo4j_session_name) ||
            fail("#{self.name} is configured to use a neo4j session named #{@neo4j_session_name}, but no such session is registered with Neo4j::Session")
        else
          Neo4j::Session.current!
        end
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
  end
end
