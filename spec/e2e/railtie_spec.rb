require 'ostruct'

module Rails
  class Config
    attr_accessor :neo4j, :session_type, :session_path, :sessions, :session_options, :wait_for_connection
    def to_hash
      {}
    end
  end

  class Railtie
    cattr_accessor :init, :conf

    class << self
      # attr_reader :init, :config

      def initializer(name, _options = {}, &block)
        Railtie.init ||= {}
        Railtie.init[name] = block
      end
    end
  end
  class App
    attr_accessor :neo4j

    def config
      self
    end

    def neo4j
      @neo4j ||= Config.new
    end
  end

  require 'neo4j/railtie'

  describe 'railtie' do
    it 'configures a default Neo4j server_db' do
      expect(Neo4j::ActiveBase).to receive(:set_current_session_by_adaptor).with(an_instance_of(Neo4j::Core::CypherSession::Adaptors::HTTP))

      app = App.new
      Railtie.init['neo4j.start'].call(app)
    end

    it 'allows sessions with additional options' do
      expect(Neo4j::Core::CypherSession::Adaptors::HTTP).to receive(:new).with('http://localhost:7474', basic_auth: {username: 'user', password: 'password'}, wrap_level: :proc).and_call_original
      app = App.new
      app.neo4j.sessions = [{type: :server_db, path: 'http://localhost:7474',
                             options: {basic_auth: {username: 'user', password: 'password'}}}]
      Railtie.init['neo4j.start'].call(app)
    end

    it 'allows sessions with authentication' do
      cfg = OpenStruct.new(session_path: 'http://user:password@localhost:7474')
      Neo4j::Railtie.setup_default_session(cfg)
      expect(cfg.session_path).to eq('http://user:password@localhost:7474')
    end

    describe 'validation' do
      let(:valid_session_options) do
        {
          type: :http,
          url: 'http://neo4j:neo4j@localhost:7474'
        }
      end

      it 'validates type' do
        app = App.new
        app.neo4j.sessions = [valid_session_options.merge(type: :invalid)]
        expect do
          Railtie.init['neo4j.start'].call(app)
        end.to raise_error(ArgumentError, /Invalid session type/)
      end
    end
  end
end
