module Neo4j
  module Migrations
    class Base < ::Neo4j::Migration
      include Neo4j::Migrations::Helpers
      include Neo4j::Migrations::Helpers::Schema
      include Neo4j::Migrations::Helpers::IdProperty
      include Neo4j::Migrations::Helpers::Relationships

      def initialize(migration_id)
        @migration_id = migration_id
      end

      def trace_execution(levels = 4)
        cyan = "\e[36m"
        clear = "\e[0m"
        green = "\e[32m"

        indent = 0
        output = ''
        trace = TracePoint.new(:call, :c_call, :return, :c_return) do |tp|
          if [:return, :c_return].include?(tp.event) && indent.nonzero?
            indent -= 1
          else
            if indent <= levels
              parts = []
              parts << ('|  ' * indent).to_s
              parts << "#{cyan if tp.event == :call}%-8s#{clear}"
              parts << "%s:%-4d %-18s\n"
              puts format(parts.join(' '), tp.event, tp.path, tp.lineno, tp.defined_class.to_s + '#' + green + tp.method_id.to_s + clear)
            end
            indent += 1
          end
        end

        trace.enable
        yield
      ensure
        trace.disable
        puts output
      end


      def migrate(method)
        ensure_schema_migration_constraint
        Benchmark.realtime do
          ActiveBase.run_transaction(transactions?) do
            if method == :up
              log_queries { up }
              trace_execution(1000) do
                SchemaMigration.create!(migration_id: @migration_id)
              end
            else
              log_queries { down }
              SchemaMigration.find_by!(migration_id: @migration_id).destroy
            end
          end
        end
      end

      def up
        fail NotImplementedError
      end

      def down
        fail NotImplementedError
      end

      private

      def log_queries
        subscriber = Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:output))
        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      def ensure_schema_migration_constraint
        SchemaMigration.first
        Neo4j::Core::Label.wait_for_schema_changes(ActiveBase.current_session)
      end
    end
  end
end
