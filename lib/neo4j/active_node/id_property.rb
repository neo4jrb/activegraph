module Neo4j::ActiveNode
  # This module makes it possible to use other IDs than the build it neo4j id (neo_id)
  #
  # @example using generated UUIDs
  #   class Person
  #     include Neo4j::ActiveNode
  #     # creates a 'secret' neo4j property my_uuid which will be used as primary key
  #     id_property :my_uuid, auto: :uuid
  #   end
  #
  # @example using user defined ids
  #   class Person
  #     include Neo4j::ActiveNode
  #     property :title
  #     validates :title, :presence => true
  #     id_property :title_id, on: :title_to_url
  #
  #     def title_to_url
  #       self.title.urlize # uses https://github.com/cheef/string-urlize gem
  #     end
  #   end
  #
  # @example using already exsting ids that you don't want a constraint added to
  #   class Person
  #     include Neo4j::ActiveNode
  #     property :title
  #     validates :title, :presence => true
  #     id_property :id, on: :id_builder, constraint: false
  #
  #     def id_builder
  #       # only need to fill this out if you're gonna write to the db
  #     end
  #   end
  #
  module IdProperty
    extend ActiveSupport::Concern
    include Accessor

    included do
      property :uuid
      alias_attribute :id, :uuid
    end

    module ClassMethods
      attr_accessor :manual_id_property

      def find_by_neo_id(id)
        find_by(neo_id: id)
      end

      def find_by_id(id)
        all.where(id_property_name => id).first
      end

      def find_by_ids(ids)
        all.where(id_property_name => ids).to_a
      end

      def id_property(name, conf = {}, inherited = false)
        self.manual_id_property = name.to_sym

        alias_attribute :id, self.manual_id_property
      end

      def id_property_name
        manual_id_property || :id
      end

      # Maybe it doesn't make sense to have this method?
      # There is always an `id_property`, there is just sometimes a manual one
      def id_property?
        manual_id_property?
      end

      def manual_id_property?
        !!manual_id_property
      end

      alias primary_key id_property_name
    end
  end
end
