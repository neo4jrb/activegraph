module Neo4j::ActiveRel
  module Type
    extend ActiveSupport::Concern

    TYPE_CLASSES = {}

#    def self.included(klass)
#      add_type_class(klass)
#    end

    def self.add_type_class(klass)
      require 'pry'
      binding.pry
      _type_classes[klass._type] = klass
    end

    def self._type_classes
      Neo4j::ActiveRel::Type::TYPE_CLASSES
    end

  end
end

