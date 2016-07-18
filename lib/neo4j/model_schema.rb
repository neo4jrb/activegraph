require 'set'
module Neo4j
  # This is here to support the removed functionality of being able to
  # defined indexes and constraints on models
  # This code should be removed later
  module ModelSchema
    MODEL_INDEXES = {}
    MODEL_CONSTRAINTS = {}

    class << self
      def add_defined_constraint(model, property_name)
        MODEL_CONSTRAINTS[model] ||= Set.new
        MODEL_CONSTRAINTS[model] << property_name
      end

      def add_defined_index(model, property_name)
        MODEL_INDEXES[model] ||= Set.new
        MODEL_INDEXES[model] << property_name
      end

      def missing_model_constraints
        constraints = Neo4j::ActiveBase.current_session.constraints(nil, type: :uniqueness)

        MODEL_CONSTRAINTS.flat_map do |model, id_property_names|
          label = model.mapped_label_name.to_s
          id_property_names.map do |id_property_name|
            [label, id_property_name] if !constraints[label] || !constraints[label].include?([id_property_name])
          end.compact
        end
      end

      def validate_model_schema!
        constraint_messages = missing_model_constraints.flat_map do |label, id_property_name|
          force_add_index_message(label, id_property_name)
        end
        if !constraint_messages.empty?
          fail <<MSG
          Some constraints were defined by the model (which is no longer support), but the constraints do not exist in the database.  Run the following to create them:

#{constraint_messages.join("\n")}
MSG
        end
      end

      def force_add_index_message(model_name, id_property_name)
        "rails generate migration ForceAddIndex#{model_name.gsub(/[^a-z0-9]/i, '')}#{id_property_name.to_s.camelize} force_add_index #{model_name} #{id_property_name}\n"
      end
    end
  end
end
