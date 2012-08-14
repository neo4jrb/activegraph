require 'orm_adapter'

module Neo4j
  module Rails
    class Model
      extend ::OrmAdapter::ToAdapter

      class OrmAdapter < ::OrmAdapter::Base
        # Do not consider these to be part of the class list
        def self.except_classes
          @@except_classes ||= []
        end

        # Gets a list of the available models for this adapter
        def self.model_classes
          ::Neo4j::Rails::Model.descendants.to_a.select { |k| !except_classes.include?(k.name) }
        end

        # get a list of column names for a given class
        def column_names
          klass._decl_props.keys
        end

        # Get an instance by id of the model
        def get!(id)
          klass.find!(wrap_key(id))
        end

        # Get an instance by id of the model
        def get(id)
          klass.find(wrap_key(id))
        end

        # Find the first instance matching conditions
        def find_first(options = {})
          conditions, order = extract_conditions!(options)
          if !order.empty?
            find_with_order(conditions, order).first
          else
            klass.first(conditions)
          end
        end


        # Find all models matching conditions
        def find_all(options = {})
          conditions, order, limit, offset = extract_conditions!(options)
          result = if !order.empty?
            find_with_order(conditions, order)
          else
            klass.all(conditions)
          end

          if limit && offset
            result.drop(offset).first(limit)
          elsif limit
            result.first(limit)
          else
            result.to_a
          end

        end

        # Create a model using attributes
        def create!(attributes = {})
          klass.create!(attributes)
        end

        # @see OrmAdapter::Base#destroy
        def destroy(object)
          object.destroy && true if valid_object?(object)
        end

        private

        def find_with_order(conditions, order)
          conditions = wild_card_condition if conditions.nil? || conditions.empty?

          result = klass.all(conditions)
          order.inject(result) do |r,spec|
            if spec.is_a?(Array)
              spec[1]==:desc ? r.desc(spec[0]) : r.asc(spec[0])
            else
              r.asc(spec)
            end
          end
        end

        def wild_card_condition
          index_key = klass._decl_props.keys.find{|k| klass.index?(k) }
          raise "Can't perform a order query when there is no lucene index (try cypher or declare an index) on #{klass}" unless index_key
          "#{index_key}: *"
        end

      end
    end
  end
end

