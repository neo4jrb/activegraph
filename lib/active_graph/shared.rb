module ActiveGraph
  module Shared
    extend ActiveSupport::Concern
    extend ActiveModel::Naming

    include ActiveModel::Conversion
    begin
    include ActiveModel::Serializers::Xml
    rescue NameError; end # rubocop:disable Lint/HandleExceptions
    include ActiveModel::Serializers::JSON

    module ClassMethods
      # TODO: Deprecate neo4j_driver_name(name)

      # remove?
      def neo4j_driver
        ActiveGraph::Base.driver
      end

      # remove?
      def current_transaction
        ActiveGraph::Base.current_transaction
      end

      # This should be used everywhere.  Should make it easy
      # to support a driver-per-model system
      def neo4j_query(*args)
        ActiveGraph::Base.query(*args)
      end

      def new_query
        ActiveGraph::Base.new_query
      end
    end

    included do
      self.include_root_in_json = ActiveGraph::Config.include_root_in_json
      @_declared_properties ||= ActiveGraph::Shared::DeclaredProperties.new(self)

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
