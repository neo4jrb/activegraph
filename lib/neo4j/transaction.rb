require 'active_support/core_ext/module/delegation'
require 'active_support/per_thread_registry'

module Neo4j
  module Transaction
    extend self

    # Provides a simple API to manage transactions for each session in a thread-safe manner
    class TransactionsRegistry
      extend ActiveSupport::PerThreadRegistry

      attr_accessor :transactions_by_session_id
    end

    class Base
      attr_reader :driver, :root

      def initialize(driver, _options = {})
        @driver = driver
        Transaction.stack_for << self

        @root = Transaction.stack_for.first
        # Neo4j::Core::Label::SCHEMA_QUERY_SEMAPHORE.lock if root?

        # @parent = session_transaction_stack.last
        # session_transaction_stack << self
      end

      def inspect
        status_string = %i[id failed? active? commit_url].map do |method|
          "#{method}: #{send(method)}" if respond_to?(method)
        end.compact.join(', ')

        "<#{self.class} [#{status_string}]"
      end

      # Commits or marks this transaction for rollback, depending on whether #mark_failed has been previously invoked.
      def close
        tx_stack = Transaction.stack_for
        fail 'Tried closing when transaction stack is empty (maybe you closed too many?)' if tx_stack.empty?
        fail "Closed transaction which wasn't the most recent on the stack (maybe you forgot to close one?)" if tx_stack.pop != self

        @closed = true

        post_close! if tx_stack.empty?
      end

      def delete
        fail 'not implemented'
      end

      def commit
        fail 'not implemented'
      end

      def autoclosed!
        @autoclosed = true if transient_failures_autoclose?
      end

      def closed?
        !!@closed
      end

      # Marks this transaction as failed,
      # which means that it will unconditionally be rolled back
      # when #close is called.
      # Aliased for legacy purposes.
      def mark_failed
        root.mark_failed if root && root != self
        @failure = true
      end
      alias failure mark_failed

      # If it has been marked as failed.
      # Aliased for legacy purposes.
      def failed?
        !!@failure
      end
      alias failure? failed?

      def mark_expired
        @parent.mark_expired if @parent
        @expired = true
      end

      def expired?
        !!@expired
      end

      def root?
        @root == self
      end

      private

      def transient_failures_autoclose?
        Gem::Version.new(@session.version) >= Gem::Version.new('2.2.6')
      end

      def autoclosed?
        !!@autoclosed
      end

      def active?
        !closed?
      end

      def post_close!
        return if autoclosed?
        if failed?
          delete
        else
          commit
        end
      end
    end

    # @return [Neo4j::Transaction::Instance]
    def new(driver)
     driver.transaction
    end

    # Runs the given block in a new transaction.
    # @param [Boolean] run_in_tx if true a new transaction will not be created, instead if will simply yield to the given block
    # @@yield [Neo4j::Transaction::Instance]
    def run(driver, run_in_tx)
      return yield(nil) unless run_in_tx

      tx = Neo4j::Transaction.new(driver)
      yield tx
    rescue Exception => e # rubocop:disable Lint/RescueException
      # print_exception_cause(e)

      tx.mark_failed unless tx.nil?
      raise e
    ensure
      tx.close unless tx.nil?
    end

    def current_for
      stack_for.first
    end

    def stack_for
      TransactionsRegistry.transactions_by_session_id ||= []
    end

    private

    def print_exception_cause(exception)
      return if !exception.respond_to?(:cause) || !exception.cause.respond_to?(:print_stack_trace)

      Core.logger.info "Java Exception in a transaction, cause: #{exception.cause}"
      exception.cause.print_stack_trace
    end
  end
end
