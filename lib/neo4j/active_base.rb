module Neo4j
  # To contain any base login for ActiveNode/ActiveRel which
  # is external to the main classes
  module ActiveBase
    MISSING_ID_PROPERTY_CONSTRAINTS = {}

    class << self
      # private?
      def current_session
        SessionRegistry.current_session.tap do |session|
          fail 'No session defined!' if session.nil?
        end
      end

      def current_transaction_or_session
        current_transaction || current_session
      end

      def query(*args)
        current_transaction_or_session.query(*args)
      end

      # Should support setting session via config options
      def current_session=(session)
        SessionRegistry.current_session = session
      end

      def current_adaptor=(adaptor)
        self.current_session = Neo4j::Core::CypherSession.new(adaptor)
      end

      def run_transaction(run_in_tx = true)
        Neo4j::Transaction.run(current_session, run_in_tx) do |tx|
          yield tx
        end
      end

      def new_transaction
        ensure_constraints_created!
        Neo4j::Transaction.new(current_session)
      end

      def new_query(options = {})
        ensure_constraints_created!
        Neo4j::Core::Query.new({session: current_session}.merge(options))
      end

      def magic_query(*args)
        if args.empty? || args.map(&:class) == [Hash]
          ActiveBase.new_query(*args)
        else
          ActiveBase.current_session.query(*args)
        end
      end

      def current_transaction
        ensure_constraints_created!
        Neo4j::Transaction.current_for(current_session)
      end

      def unique_constraint_exists?(label, property)
        fetch_unique_constraints if !@unique_constraints

        if check_unique_constraint_exists?(label, property)
          true
        else
          fetch_unique_constraints
          check_unique_constraint_exists?(label, property)
        end
      end

      def label_object(label_name)
        Neo4j::Core::Label.new(label_name, current_session)
      end

      def logger
        Neo4j::Config[:logger] || Logger.new
      end

      def id_property_constraints_missing?
        if !MISSING_ID_PROPERTY_CONSTRAINTS.empty?
          refresh_missing_id_property_constraints!
          !MISSING_ID_PROPERTY_CONSTRAINTS.empty?
        end
      end

      def missing_id_property_constraints
        MISSING_ID_PROPERTY_CONSTRAINTS
      end

      def refresh_missing_id_property_constraints!
        MISSING_ID_PROPERTY_CONSTRAINTS.each do |model, id_property_name|
          if unique_constraint_exists?(model.mapped_label_name, id_property_name)
            MISSING_ID_PROPERTY_CONSTRAINTS.delete(model)
          end
        end
      end

      private

      def ensure_constraints_created!
        if id_property_constraints_missing?
          message = <<MSG
          Model constraints for ID properties must exist.  Run the following to create them:

MSG

          missing_id_property_constraints.each do |model, id_property_name|
            message << "rails generate migration ForceAddIndex#{model.name.gsub(/[^a-z0-9]/i, '')}#{id_property_name.to_s.camelize} force_add_index #{model.name} #{id_property_name}\n"
          end

          fail message
        end
      end

      def fetch_unique_constraints
        @unique_constraints = current_session.constraints(nil, type: :uniqueness)
      end

      def check_unique_constraint_exists?(label, property)
        label_constraints = @unique_constraints[label.to_s]
        label_constraints && label_constraints.include?([property.to_sym])
      end
    end
  end
end
