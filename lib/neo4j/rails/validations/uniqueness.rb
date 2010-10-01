module Neo4j
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator
      def initialize(options)
        super(options.reverse_merge(:case_sensitive => true))
      end

      def validate_each(record, attribute, value)
        clazz = record.class

        # TODO is it possible to move this to setup instead so that we don't have to do this always ?
        if clazz.index_type_for(attribute) != :exact
          raise "Can't validate property #{attribute} on class #{clazz} since there is no :exact lucene index on that property"
        end

        query = "#{attribute}: #{value}"
        if !clazz.find(query).empty?
          record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
        end
      end
    end

    module ClassMethods
      def validates_uniqueness_of(*attr_names)
        validates_with UniquenessValidator, _merge_attributes(attr_names)
      end
    end
  end
end
