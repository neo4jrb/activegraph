# frozen_string_literal: true

module ActiveGraph
  module Transactions
    extend ActiveSupport::Concern

    included do
      thread_mattr_accessor :explicit_session, :tx
    end

    class_methods do
      def session(*args)
        driver.session(*args) do |session|
          self.explicit_session = session
          yield session
          session.last_bookmark
        end
      end

      def transaction(**config, &block)
        send_transaction(:begin_transaction, **config, &block)
      end

      def write_transaction(**config, &block)
        send_transaction(:write_transaction, **config, &block)
      end

      def read_transaction(**config, &block)
        send_transaction(:read_transaction, **config, &block)
      end

      private

      def send_transaction(method, **config, &block)
        return checked_yield(tx, &block) if tx&.open?
        return run_transaction_work(explicit_session, method, **config, &block) if explicit_session&.open?
        driver.session do |session|
          run_transaction_work(session, method, **config, &block)
        end
      end

      def run_transaction_work(session, method, **config, &block)
        session.send(method, **config) do |tx|
          self.tx = tx
          checked_yield(tx, &block)
        end
      end

      def checked_yield(tx)
        yield tx
      rescue StandardError => e
        tx.failure
        raise e
      end
    end
  end
end
