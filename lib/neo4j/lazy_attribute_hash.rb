require "active_model/attribute_set"

module Neo4j
  class LazyAttributeHash < ActiveModel::LazyAttributeHash
    def initialize(values)
      @types = {}
      @values = values
      @additional_types = {}
      @materialized = false
      @delegate_hash = {}
      @default_attributes = {}
    end
  end
end
