module Neo4j::ActiveNode
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Shared::Property

    def initialize(attributes = nil)
      super(attributes)
      @attributes ||= Hash[self.class.attributes_nil_hash]
    end

    module ClassMethods
      # Extracts keys from attributes hash which are associations of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_association_attributes!(attributes)
        return unless contains_association?(attributes)
        attributes.each_with_object({}) do |(key, _), result|
          result[key] = attributes.delete(key) if self.association_key?(key)
        end
      end

      def association_key?(key)
        association_method_keys.include?(key.to_sym)
      end

      private

      def contains_association?(attributes)
        return false unless attributes
        attributes.each_key { |k| return true if association_key?(k) }
        false
      end

      # All keys which could be association setter methods (including _id/_ids)
      def association_method_keys
        @association_method_keys ||=
          associations_keys.map(&:to_sym) +
          associations.values.map do |association|
            if association.type == :has_one
              "#{association.name}_id"
            elsif association.type == :has_many
              "#{association.name.to_s.singularize}_ids"
            end.to_sym
          end
      end
    end

    private

    def inspect_attributes
      id_property_name = self.class.id_property_name.to_s

      attribute_pairs = attributes.except(id_property_name).sort.map do |key, value|
        [key, (value.is_a?(String) && value.size > 100) ? value.dup[0..100] : value]
      end

      attribute_pairs.unshift([id_property_name, self.send(id_property_name)])
      attribute_pairs
    end
  end
end
