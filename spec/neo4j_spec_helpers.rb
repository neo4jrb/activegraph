module Neo4jSpecHelpers
  extend ActiveSupport::Concern

  class << self
    attr_accessor :expect_queries_count
  end

  self.expect_queries_count = 0

  ActiveGraph::Base.subscribe_to_query do |_message|
    self.expect_queries_count += 1
  end

  def expect_queries(count, &block)
    expect(queries_count(&block)).to eq(count)
  end

  def queries_count
    start_count = Neo4jSpecHelpers.expect_queries_count
    yield
    Neo4jSpecHelpers.expect_queries_count - start_count
  end

  def new_query
    ActiveGraph::Base.new_query
  end

  def driver
    ActiveGraph::Base.driver
  end

  def neo4j_query(*args)
    ActiveGraph::Base.query(*args)
  end

  def action_controller_params(args)
    ActionController::Parameters.new(args)
  end

  class_methods do
    def let_config(var_name, value)
      around do |example|
        old_value = ActiveGraph::Config[var_name]
        ActiveGraph::Config[var_name] = value
        example.run
        ActiveGraph::Config[var_name] = old_value
      end
    end

    def capture_output!(variable)
      around do |example|
        @captured_stream = StringIO.new

        original_stream = $stdout
        $stdout = @captured_stream

        example.run

        $stdout = original_stream
      end
      let(variable) { @captured_stream.string }
    end

    def let_env_variable(var_name)
      around do |example|
        old_value = ENV[var_name.to_s]
        ENV[var_name.to_s] = yield
        example.run
        ENV[var_name.to_s] = old_value
      end
    end
  end
end
