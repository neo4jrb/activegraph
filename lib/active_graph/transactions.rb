# frozen_string_literal: true

module ActiveGraph
  module Transactions
    extend ActiveSupport::Concern

    included do
      thread_mattr_accessor :explicit_session, :tx, :last_bookmark
    end

    class_methods do
      def session(**session_config)
        ActiveGraph::Base.driver.session(**session_config) do |session|
          self.explicit_session = session
          yield session
        ensure
          self.last_bookmark = session.last_bookmark
        end
      end

      def write_transaction(**config, &block)
        send_transaction(:write_transaction, **config, &block)
      end

      def read_transaction(**config, &block)
        send_transaction(:read_transaction, **config, &block)
      end

      alias transaction write_transaction

      private

      def send_transaction(method, **config, &block)
        return yield tx if tx&.open?
        return run_transaction_work(explicit_session, method, **config, &block) if explicit_session&.open?
        driver.session do |session|
          run_transaction_work(session, method, **config, &block)
        end
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
      end
    end
  end
end
