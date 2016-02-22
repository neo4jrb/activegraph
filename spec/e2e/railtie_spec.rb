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
      expect(Neo4j::Session).to receive(:open).with(:server_db, server_url, default: true).and_return(double)
      app = App.new
      Railtie.init['neo4j.start'].call(app)
    end

    it 'allows multi session' do
      expect(Neo4j::Session).to receive(:open).with(:mysession_type, 'asd', nil).and_return(double)
      app = App.new
      app.neo4j.sessions = [{type: :mysession_type, path: 'asd'}]
      Railtie.init['neo4j.start'].call(app)
    end

    it 'allows sessions with additional options' do
      expect(Neo4j::Session).to receive(:open).with(:server_db, 'http://localhost:7474', basic_auth: {username: 'user', password: 'password'}).and_return(double)
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

    it 'allows named session' do
      expect(Neo4j::Session).to receive(:open_named).with('type', 'name', 'default', 'path').and_return(double)
      app = App.new
      app.neo4j.sessions = [{type: 'type', name: 'name', default: 'default', path: 'path'}]
      Railtie.init['neo4j.start'].call(app)
    end
  end
end
