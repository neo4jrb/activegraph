module Neo4j
  module ActiveNode
    module Dependent
      module AssociationMethods
        def validate_dependent(value)
          fail ArgumentError, "Invalid dependent value: #{value.inspect}" if not valid_dependent_value?(value)
        end

        def add_destroy_callbacks(model)
          return if dependent.nil?

          model.before_destroy(&method("dependent_#{dependent}_callback"))
        rescue NameError
          raise "Unknown dependent option #{dependent}"
        end

        private

        def valid_dependent_value?(value)
          return true if value.nil?

          self.respond_to?("dependent_#{value}_callback", true)
        end

        # Callback methods
        def dependent_delete_callback(object)
          object.association_query_proxy(name).delete_all
        end

        def dependent_delete_orphans_callback(object)
          object.as(:self).unique_nodes(self, :self, :n, :other_rel).query.delete(:n, :other_rel).exec
        end

        def dependent_destroy_callback(object)
          unique_query = object.association_query_proxy(name)
          unique_query.each_for_destruction(object, &:destroy) if unique_query
        end

        def dependent_destroy_orphans_callback(object)
          unique_query = object.as(:self).unique_nodes(self, :self, :n, :other_rel)
          unique_query.each_for_destruction(object, &:destroy) if unique_query
        end

        # End callback methods
      end
    end
  end
end
