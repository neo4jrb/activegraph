module Neo4jSpecHelpers
  extend ActiveSupport::Concern

  class << self
    attr_accessor :expect_queries_count
  end

  self.expect_queries_count = 0

  Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query do |_message|
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
    Neo4j::ActiveBase.new_query
  end

  def current_session
    Neo4j::ActiveBase.current_session
  end

  def neo4j_query(*args)
    current_session.query(*args)
  end

  def log_queries!
    Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:puts))
  end

  def action_controller_params(args)
    ActionController::Parameters.new(args)
  end

  def handle_child_output(read, write)
    read.close
    begin
      rest = yield
      write.puts [Marshal.dump(rest)].pack('m')
    rescue StandardError => e
      write.puts [Marshal.dump(e)].pack('m')
    end
    exit!
  end

  def do_in_child(&block)
    read, write = IO.pipe
    pid = fork do
      handle_child_output(read, write, &block)
    end
    write.close
    result = Marshal.load(read.read.unpack('m').first)
    Process.wait2(pid)

    fail result if result.class < Exception
    result
  end

  # A trick to load action_controller without requiring in all specs. Not working in JRuby.
  def using_action_controller
    if RUBY_PLATFORM == 'java'
      require 'action_controller'
      yield
    else
      do_in_child do
        require 'action_controller'
        yield
      end
    end
  end

  class_methods do
    def let_config(var_name, value)
      around do |example|
        old_value = Neo4j::Config[var_name]
        Neo4j::Config[var_name] = value
        example.run
        Neo4j::Config[var_name] = old_value
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

  def test_bolt_url
    ENV['NEO4J_URL']
  end

  def test_driver_adaptor(url, extra_options = {})
    options = {}
    options[:logger_level] = Logger::DEBUG if ENV['DEBUG']

    Neo4j::Core::CypherSession::Adaptors::Driver.new(url, options.merge(extra_options))
  end
end
