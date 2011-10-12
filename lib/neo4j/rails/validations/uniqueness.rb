module Neo4j
  module Rails
    module Validations
      extend ActiveSupport::Concern

      class UniquenessValidator < ActiveModel::EachValidator
        def initialize(options)
          super(options.reverse_merge(:case_sensitive => true))
            @validator =  options[:case_sensitive].nil? || options[:case_sensitive] ? ExactMatchValidator : FulltextMatchValidator
        end

        def setup(klass)
          @attributes.each do |attribute|
            if klass.index_type_for(attribute) != @validator.index_type
              raise index_error_message(klass,attribute,@validator.index_type)
            end
          end
        end

        def index_error_message(klass,attribute,index_type)
          "Can't validate property #{attribute.inspect} on class #{klass} since there is no :#{index_type} lucene index on that property or the index declaration #{attribute} comes after the validation declaration in #{klass} (try to move it before the validation rules)"
        end

        def validate_each(record, attribute, value)
          return if options[:allow_blank] && value.blank?
          @validator.query(record.class,attribute,value).each do |rec|
            if rec.id != record.id # it doesn't count if we find ourself!
              if @validator.match(rec, attribute, value)
                record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
              end
              break
            end
          end
        end
      end

      class ExactMatchValidator
        def self.index_type
          :exact
        end

        def self.query(model,attribute,value)
          model.all("#{attribute}: \"#{value}\"")
        end

        def self.match(rec,attribute,value)
          rec[attribute] == value
        end
      end

      class FulltextMatchValidator
        def self.index_type
          :fulltext
        end

        def self.query(model,attribute,value)
          value.blank? ? model.all("*:* -#{attribute}:[* TO *]", :type => :fulltext) : model.all("#{attribute}: \"#{value}\"", :type => :fulltext)
        end

        def self.match(rec,attribute,value)
          rec[attribute].downcase == value.downcase
        end
      end

      module ClassMethods
        def validates_uniqueness_of(*attr_names)
          validates_with UniquenessValidator, _merge_attributes(attr_names)
        end
      end
    end
  end
end
