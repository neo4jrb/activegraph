require 'spec_helper'
require 'ostruct'

module Rails
  class Config
    attr_accessor :neo4j, :session_type, :session_path, :sessions, :session_options
    def to_hash
      {}
    end
  end

  class Railtie
    cattr_accessor :init, :conf

    class << self
      #attr_reader :init, :config

      def initializer(name, options={}, &block)
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
      expect(Neo4j::Session).to receive(:open).with(:server_db, 'http://localhost:7474', {})
      app = App.new
      Railtie.init['neo4j.start'].call(app)
    end

    it 'allows multi session' do
      expect(Neo4j::Session).to receive(:open).with(:mysession_type, "asd", nil)
      app = App.new
      app.neo4j.sessions = [{type: :mysession_type, path: 'asd'}]
      Railtie.init['neo4j.start'].call(app)
    end

    it 'allows sessions with additional options' do
      expect(Neo4j::Session).to receive(:open).with(:server_db, 'http://localhost:7474', basic_auth: {username: 'user', password: 'password'})
      app = App.new
      app.neo4j.sessions = [{type: :server_db, path: 'http://localhost:7474',
                             options: {basic_auth: {username: 'user', password: 'password'}}}]
      Railtie.init['neo4j.start'].call(app)
    end

    it 'allows sessions with authentication' do
      cfg = OpenStruct.new(session_path: 'http://user:password@localhost:7474')
      Neo4j::Railtie.set_default_session(cfg)
      cfg.session_path.should == 'http://localhost:7474'
      cfg.session_options.should == {basic_auth: {username: 'user', password: 'password'}}
    end

    it 'allows named session' do
      expect(Neo4j::Session).to receive(:open_named).with('type', 'name', 'default', 'path')
      app = App.new
      app.neo4j.sessions = [{type: 'type', name: 'name', default: 'default', path: 'path'}]
      Railtie.init['neo4j.start'].call(app)
    end

    it 'raise exception if try to run embedded in no JRUBY environemt' do
      app = App.new
      allow(Railtie).to receive(:java_platform?).and_return(true)
      app.neo4j.sessions = [{type: :embedded_db, path: 'asd'}]

      expect do
        Railtie.init['neo4j.start'].call(app)
      end.to raise_error
    end
  end
end
