require 'orm_adapter'

module Neo4j
  module ActiveNode
    module ClassMethods
      include OrmAdapter::ToAdapter
    end

    class OrmAdapter < ::OrmAdapter::Base
      module ClassMethods
        include ActiveModel::Callbacks
      end

      def column_names
        klass._decl_props.keys
      end

      # Get an instance by id of the model
      def get!(id)
        klass.find(wrap_key(id)).tap do |node|
          raise "No record found" if node.nil?
        end
      end

      # Get an instance by id of the model
      def get(id)
        klass.find(wrap_key(id))
      end

      # Find the first instance matching conditions
      def find_first(options = {})
        conditions, order = extract_conditions!(options)
        extract_id!(conditions)
        if !order.empty?
          find_with_order(conditions, order).to_a.first
        else
          result = klass.find(conditions)
          result
        end
      end

      # Find all models matching conditions
      def find_all(options = {})
        conditions, order, limit, offset = extract_conditions!(options)
        extract_id!(conditions)
        result = if !order.empty?
          find_with_order(conditions, order)
        else
          klass.all(conditions)
        end

        if limit && offset
          result.drop(offset).first(limit)
        elsif limit
          result.to_a.first(limit)
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

      def extract_id!(conditions)
        if id = conditions.delete(:id)
          conditions[:neo_id] = id 
        end
      end

      def find_with_order(conditions, order)
        result = klass.all(conditions.merge(order: order.map {|clause| Hash[*clause] }))
      end

    end
  end
end

