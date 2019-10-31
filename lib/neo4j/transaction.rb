require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/attribute_accessors_per_thread'

module Neo4j
  class Transaction
    thread_mattr_accessor :stack
    attr_reader :driver, :root
    attr_reader :driver_tx, :driver_session

    class << self
      # Runs the given block in a new transaction.
      # @param [Boolean] run_in_tx if true a new transaction will not be created, instead if will simply yield to the given block
      # @@yield [Neo4j::Transaction::Instance]
      def run(driver, run_in_tx)
        return yield(nil) unless run_in_tx

        tx = Neo4j::Transaction.new(driver)
        yield tx
      rescue Exception => e # rubocop:disable Lint/RescueException

        tx.mark_failed unless tx.nil?
        raise e
      ensure
        tx.close unless tx.nil?
      end

      def root
        stack.first
      end
    end

    def initialize(driver, _options = {})
      @driver = driver
      (self.stack ||= []) << self

      @root = stack.first
      return unless root?
      @driver_session = driver.driver.session(Neo4j::Driver::AccessMode::WRITE)
      @driver_tx = @driver_session.begin_transaction
    rescue StandardError => e
      self.stack = []
      @driver_tx.close if @driver_tx
      @driver_session.close if @driver_session
      raise e
    end

    # Commits or marks this transaction for rollback, depending on whether #mark_failed has been previously invoked.
    def close
      fail 'Tried closing when transaction stack is empty (maybe you closed too many?)' if stack.empty?
      fail "Closed transaction which wasn't the most recent on the stack (maybe you forgot to close one?)" if stack.pop != self

      post_close! if stack.empty?
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

    def root?
      @root == self
    end

    def query(*args)
      options = if args[0].is_a?(::Neo4j::Core::Query)
                  args[1] ||= {}
                else
                  args[1] ||= {}
                  args[2] ||= {}
                end
      options[:transaction] ||= self

      driver.query(*args)
    end

    def queries(options = {}, &block)
      driver.queries({ transaction: self }.merge(options), &block)
    end

    def after_commit_registry
      @after_commit_registry ||= []
    end

    def after_commit(&block)
      after_commit_registry << block
    end

    def commit
      return unless root?
      begin
        @driver_tx.success
        @driver_tx.close
      ensure
        @driver_session.close
      end
    end

    def delete
      root.driver_tx.failure
      root.driver_tx.close
      root.driver_session.close
    end

    def root_tx
      root.driver_tx
    end

    private

    def post_close!
      if failed?
        delete
      else
        commit
        after_commit_registry.each(&:call)
      end
    end
  end
end
