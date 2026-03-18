# frozen_string_literal: true

module ActiveGraph
  module Transactions
    extend ActiveSupport::Concern

    included do
      thread_mattr_accessor :explicit_session, :tx, :last_bookmarks
    end

    class_methods do
      def session(**session_config)
        ActiveGraph::Base.driver.session(**session_config) do |session|
          self.explicit_session = session
          yield session
        ensure
          self.last_bookmarks = session.last_bookmarks
        end
      end

      def write_transaction(**config, &block)
        send_transaction(:execute_write, **config, &block)
      end

      def read_transaction(**config, &block)
        send_transaction(:execute_read, **config, &block)
      end

      alias transaction write_transaction

      def lock_node(node)
        node.as(:n).query.remove('n._AGLOCK_').exec if tx
      end

      private

      def send_transaction(method, **config, &block)
        return run_transaction_work(explicit_session, method, **config, &block) if !tx && explicit_session&.open?
        return driver.session { |session| run_transaction_work(session, method, **config, &block) } unless tx

        yield tx
      rescue ActiveGraph::Rollback
        false
      end

      def run_transaction_work(session, method, **config, &block)
        implicit = config.delete(:implicit)
        session.send(method, **config) do |tx|
          self.tx = tx
          block.call(tx).tap do |result|
            if implicit &&
              [Core::Result, ActiveGraph::Node::Query::QueryProxy, ActiveGraph::Core::Query]
                .any?(&result.method(:is_a?))
              result.store
            end
          end
        end.tap { tx.apply_callbacks }
      rescue ActiveGraph::Rollback
        # rollbacks are silently swallowed
        false # to satisfy save and update conventions
      ensure
        self.tx = nil
      end
    end
  end
end
