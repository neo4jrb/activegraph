module ActiveGraph
  # To contain any base login for Node/Relationship which
  # is external to the main classes
  module Base
    include ActiveGraph::Transactions

    at_exit do
      @driver&.close
    end

    class << self
      # private?
      def current_driver
        (@driver ||= establish_driver).tap do |driver|
          fail 'No driver defined!' if driver.nil?
        end
      end

      def driver
        current_driver.driver
      end

      def on_establish_driver(&block)
        @establish_driver_block = block
      end

      def establish_driver
        @establish_driver_block.call if @establish_driver_block
      end

      def new_driver(url, auth_token, options = {})
        verbose_query_logs = ActiveGraph::Config.fetch(:verbose_query_logs, false)
        ActiveGraph::Core::Driver
          .new(url, auth_token, options, verbose_query_logs: verbose_query_logs)
      end

      def transaction
        current_transaction || Transaction
      end

      def query(*args)
        transaction.query(*args)
      end

      # Should support setting driver via config options
      def driver=(driver)
        @driver&.close
        @driver = driver
      end

      def run_transaction(run_in_tx = true)
        Transaction.run(current_driver, run_in_tx) do |tx|
          yield tx
        end
      end

      def new_transaction
        validate_model_schema!
        ActiveGraph::Transaction.new
      end

      def new_query(options = {})
        validate_model_schema!
        ActiveGraph::Core::Query.new({driver: current_driver}.merge(options))
      end

      def magic_query(*args)
        if args.empty? || args.map(&:class) == [Hash]
          Base.new_query(*args)
        else
          Base.current_driver.query(*args)
        end
      end

      def current_transaction
        validate_model_schema!
        Transaction.root
      end

      def label_object(label_name)
        ActiveGraph::Core::Label.new(label_name)
      end

      def logger
        @logger ||= (ActiveGraph::Config[:logger] || ActiveSupport::Logger.new(STDOUT))
      end

      private

      def validate_model_schema!
        ActiveGraph::ModelSchema.validate_model_schema! unless ActiveGraph::Migrations.currently_running_migrations
      end
    end
  end
end
