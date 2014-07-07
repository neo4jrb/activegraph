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

      def i18n_scope
        :neo4j
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
        order = hasherize_order(order)

        result = klass.query_as(:n).where(conditions)
        result = result.order(order) if !order.empty?

        result.first[:n]
      end

      # Find all models matching conditions
      def find_all(options = {})
        conditions, order, limit, offset = extract_conditions!(options)
        extract_id!(conditions)
        order = hasherize_order(order)

        result = klass.query_as(:n).where(n: conditions)
        result = result.order(order).limit(limit).skip(offset) if !order.empty?

        result.to_a
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

      def hasherize_order(order)
        (order || []).map {|clause| Hash[*clause] }
      end

      def extract_id!(conditions)
        if id = conditions.delete(:id)
          conditions['id(n)'] = id.to_i
        end
      end

    end
  end
end

