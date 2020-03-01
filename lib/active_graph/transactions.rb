# frozen_string_literal: true

module ActiveGraph
  module Transactions
    extend ActiveSupport::Concern

    included do
      thread_mattr_accessor :ag_session, :tx
    end

    class_methods do
      def session(*args)
        driver.session(*args) do |session|
          self.ag_session = session
          yield session
          session.last_bookmark
        ensure
          self.ag_session = nil
        end
      end

      def write_transaction(config = nil, &block)
        send_transaction(:write_transaction, config, &block)
      end
      alias transaction write_transaction

      def read_transaction(config = nil, &block)
        send_transaction(:read_transaction, config, &block)
      end

      def begin_transaction(config = nil, &block)
        send_transaction(:begin_transaction, config, &block)
      end

      private

      def send_transaction(method, config = nil, &block)
        return yield tx if tx
        return reuse(ag_session, method, config, &block) if ag_session
        driver.session { |session| reuse(session, method, config, &block) }
      end

      def reuse(session, method, config)
        session.send(method, config) do |tx|
          self.tx = tx
          yield tx
          tx.success
        ensure
          self.tx = nil
        end
      end
    end
  end
end
