require 'ostruct'

module Rails
  describe 'railtie' do
    before do
      # stub_named_class('Config') do
      #   attr_accessor :neo4j, :session_type, :session_path, :sessions, :session_options, :wait_for_connection
      #   def to_hash
      #     {}
      #   end
      # end

      # stub_named_class('Railtie') do
      #   cattr_accessor :init, :conf

      #   class << self
      #     # attr_reader :init, :config

      #     def initializer(name, _options = {}, &block)
      #       Railtie.init ||= {}
      #       Railtie.init[name] = block
      #     end
      #   end
      # end

      # stub_named_class('App') do
      #   attr_accessor :neo4j

      #   def config
      #     self
      #   end

      #   def neo4j
      #     @neo4j ||= Config.new
      #   end
      # end
    end

    require 'neo4j/railtie'

    around(:each) do |example|
      main_spec_session = Neo4j::ActiveBase.current_session
      example.run
      Neo4j::ActiveBase.set_current_session(main_spec_session)
    end

    describe 'open_neo4j_session' do
      subject { Neo4j::Railtie.open_neo4j_session(session_options) }

      if TEST_SESSION_MODE == :embedded
        let_context(session_options: {type: :embedded, path: './db'}) do
          subject_should_raise(ArgumentError, /Tried to start embedded Neo4j db without using JRuby/)
        end
      end

      let_context(session_options: {type: :invalid_type}) do
        subject_should_raise(ArgumentError, /Invalid session type/)
      end

      describe 'resulting adaptor' do
        subject do
          super()
          Neo4j::ActiveBase.current_session.adaptor
        end

        let_context(session_options: {type: :http, url: 'http://neo4j:specs@the_host:1234'}) do
          it { should be_a(Neo4j::Core::CypherSession::Adaptors::HTTP) }
          its(:url) { should eq('http://neo4j:specs@the_host:1234') }

          describe 'faraday connection' do
            subject { super().requestor.instance_variable_get('@faraday') }

            its('url_prefix.host') { should eq('the_host') }
            its('url_prefix.port') { should eq(1234) }
            describe 'headers' do
              subject { super().headers }
              its(['Authorization']) { should eq "Basic #{Base64.strict_encode64('neo4j:specs')}" }
            end
          end
        end

        let_context(session_options: {type: :http, url: 'http://neo4j:specs@the_host:1234', options: {basic_auth: 'neo4j', password: 'specs2'}}) do
          it { should be_a(Neo4j::Core::CypherSession::Adaptors::HTTP) }
          its(:url) { should eq('http://neo4j:specs@the_host:1234') }

          describe 'faraday connection' do
            subject { super().requestor.instance_variable_get('@faraday') }

            its('url_prefix.host') { should eq('the_host') }
            its('url_prefix.port') { should eq(1234) }
            describe 'headers' do
              subject { super().headers }
              its(['Authorization']) { should eq "Basic #{Base64.strict_encode64('neo4j:specs')}" }
            end
          end
        end

        if TEST_SESSION_MODE == :embedded
          let_context(session_options: {type: :embedded, path: './db'}) do
            it { should be_a(Neo4j::Core::CypherSession::Adaptors::Embedded) }
            its(:path) { should eq('./db') }
          end
        end
      end
    end
  end
end
