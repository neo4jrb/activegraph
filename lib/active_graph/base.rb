module ActiveGraph
  # To contain any base login for Node/Relationship which
  # is external to the main classes
  module Base
    include ActiveGraph::Transactions
    include ActiveGraph::Core::Querable
    extend ActiveGraph::Core::Schema

    at_exit do
      @driver&.close
    end

    class << self
      # private?
      def driver
        (@driver ||= establish_driver).tap do |driver|
          fail 'No driver defined!' if driver.nil?
        end
      end

      def on_establish_driver(&block)
        @establish_driver_block = block
      end

      def establish_driver
        @establish_driver_block.call if @establish_driver_block
      end

      def query(*args)
        transaction(implicit: true) do
          super(*args)
        end
      end

      # Should support setting driver via config options
      def driver=(driver)
        @driver&.close
        @driver = driver
        forget_server
      end

      # Whether a driver is set or can be established, establishing it when a block was registered. Without
      # one queries can be built, not run.
      def driver?
        !(@driver ||= establish_driver).nil?
      end

      # The cypher-dsl renderer for the connected server, see Core::Schema#dialect. `pretty: true`
      # renders one clause per line.
      def renderer(pretty: false)
        dialect = self.dialect
        renderers.compute_if_absent([dialect, pretty]) do
          CypherDSL::Renderer.get_renderer(
            CypherDSL::Renderer::Configuration.new_config.with_dialect(dialect).with_pretty_print(pretty)
                                                           .always_escape_names(true).build
          )
        end
      end

      def validating_transaction(&block)
        validate_model_schema!
        transaction(&block)
      end

      def new_query(options = {})
        validate_model_schema!
        ActiveGraph::Core::Query.new(options)
      end

      def magic_query(*args)
        if args.empty? || args.map(&:class) == [Hash]
          new_query(*args)
        else
          query(*args)
        end
      end

      def label_object(label_name)
        ActiveGraph::Core::Label.new(label_name)
      end

      def element(name, relationship: false)
        (relationship ? Core::Type : Core::Label).new(name)
      end

      def logger
        @logger ||= (ActiveGraph::Config[:logger] || ActiveSupport::Logger.new(STDOUT))
      end

      private

      def renderers
        @renderers ||= Concurrent::Map.new
      end

      # What was learned about the server of the previous driver: its version and the dialect it speaks.
      def forget_server
        @component = @major = @dialect = @renderers = nil
      end

      def validate_model_schema!
        ActiveGraph::ModelSchema.validate_model_schema! unless ActiveGraph::Migrations.currently_running_migrations
      end
    end
  end
end
