require 'ostruct'

module Rails
  describe 'railtie' do
    require 'neo4j/railtie'


    around(:each) do |example|
      main_spec_session = Neo4j::ActiveBase.current_session
      example.run
      Neo4j::ActiveBase.current_session = main_spec_session
    end

    describe '#setup!' do
      let(:session_path) {}
      let(:session_type) {}
      let(:cfg) do
        ActiveSupport::OrderedOptions.new.tap do |c|
          c.session = ActiveSupport::OrderedOptions.new
          c.session.path = session_path if session_path
          c.session.type = session_type if session_type
        end
      end

      let(:raise_expectation) { [:not_to, raise_error] }

      context 'errors' do
        before do
          expect do
            Neo4j::Railtie.setup!(cfg)
          end.send(*raise_expectation)
        end

        let(:raise_expectation) { [:to, raise_error(ArgumentError, 'Invalid session type: :foo (expected one of [:http, :bolt, :embedded])')] }
        let_context(session_type: :foo) do
          it { 1 }
        end
      end

      context 'no errors' do
        before do
          stub_const('Neo4j::SessionManager', spy('Neo4j::SessionManager'))

          expect do
            Neo4j::Railtie.setup!(cfg)
          end.send(*raise_expectation)
        end

        let_context(session_type: :http) do
          # Expect to not raise
          it { 1 }
        end

        let_context(session_path: 'http://user:password@localhost:7474') do
          let_env_variable(:NEO4J_URL) { nil }
          it 'calls Neo4j::SessionManager' do
            expect(Neo4j::SessionManager).to have_received(:open_neo4j_session).with(:http, 'http://user:password@localhost:7474', nil, {})
          end
        end

        context 'NEO4J_URL is http' do
          let_env_variable(:NEO4J_URL) { 'http://localhost:7474' }

          it 'calls Neo4j::SessionManager' do
            expect(Neo4j::SessionManager).to have_received(:open_neo4j_session).with(:http, 'http://localhost:7474', nil, {})
          end
        end

        context 'NEO4J_URL is bolt' do
          let_env_variable(:NEO4J_URL) { 'bolt://localhost:7472' }

          it 'calls Neo4j::SessionManager' do
            expect(Neo4j::SessionManager).to have_received(:open_neo4j_session).with(:bolt, 'bolt://localhost:7472', nil, {})
          end
        end

        context 'NEO4J_URL is https' do
          let_env_variable(:NEO4J_URL) { 'https://localhost:7472' }

          it 'calls Neo4j::SessionManager' do
            expect(Neo4j::SessionManager).to have_received(:open_neo4j_session).with(:http, 'https://localhost:7472', nil, {})
          end
        end
      end
    end

    describe '#support_deprecated_session_configs!' do
      let(:config) { ActiveSupport::InheritableOptions.new(session: ActiveSupport::OrderedOptions.new) }

      it 'uses sessions if present' do
        config.sessions = [:abc]
        Neo4j::Railtie.support_deprecated_session_configs!(config)
        expect(config.session).to eq(:abc)
      end

      it 'leverages session_type if present' do
        config.session_type = :bolt
        Neo4j::Railtie.support_deprecated_session_configs!(config)
        expect(config.session.type).to eq(:bolt)
      end
    end

    describe 'open_neo4j_session' do
      let(:session_type) { nil }
      let(:session_path_or_url) { nil }
      let(:session_options) { {} }
      subject { Neo4j::SessionManager.open_neo4j_session(session_type, session_path_or_url, nil, session_options) }

      if TEST_SESSION_MODE != :embedded
        let_context(session_type: :embedded, session_path_or_url: './db') do
          subject_should_raise(/JRuby is required for embedded mode/)
        end
      end

      let_context(session_type: :invalid_type) do
        subject_should_raise(ArgumentError, /Invalid session type: :invalid_type/)
      end

      let_context(session_type: :server_db) do
        subject_should_raise(ArgumentError, /Invalid session type: :server_db .*\(`server_db` has been replaced/)
      end

      describe 'resulting adaptor' do
        subject do
          super().adaptor
        end

        let_context(session_type: :http, session_path_or_url: 'http://neo4j:specs@the-host:1234') do
          it { should be_a(Neo4j::Core::CypherSession::Adaptors::HTTP) }
          its(:url) { should eq('http://neo4j:specs@the-host:1234') }

          describe 'faraday connection' do
            subject { super().requestor.instance_variable_get('@faraday') }

            its('url_prefix.host') { should eq('the-host') }
            its('url_prefix.port') { should eq(1234) }
            describe 'headers' do
              subject { super().headers }
              its(['Authorization']) { should eq "Basic #{Base64.strict_encode64('neo4j:specs')}" }
            end
          end
        end

        let_context(session_type: :http, session_path_or_url: 'http://neo4j:specs@the-host:1234', session_options: {basic_auth: 'neo4j', password: 'specs2'}) do
          it { should be_a(Neo4j::Core::CypherSession::Adaptors::HTTP) }
          its(:url) { should eq('http://neo4j:specs@the-host:1234') }

          describe 'faraday connection' do
            subject { super().requestor.instance_variable_get('@faraday') }

            its('url_prefix.host') { should eq('the-host') }
            its('url_prefix.port') { should eq(1234) }
            describe 'headers' do
              subject { super().headers }
              its(['Authorization']) { should eq "Basic #{Base64.strict_encode64('neo4j:specs')}" }
            end
          end
        end

        if TEST_SESSION_MODE == :embedded
          require 'tmpdir'

          context 'embedded session options' do
            let(:tmpdir) { Dir.mktmpdir }
            let(:session_type) { :embedded }
            let(:session_path_or_url) { tmpdir }

            # Mocking the embedded connection, to avoid `OutOfMemory` on Travis
            # This checks that the connection would be created
            before(:each) do
              expect_any_instance_of(Neo4j::Core::CypherSession::Adaptors::Embedded).to receive(:connect)
            end

            it { should be_a(Neo4j::Core::CypherSession::Adaptors::Embedded) }
            its(:path) { is_expected.to eq(tmpdir) }
          end
        end
      end
    end

    describe '#cypher_session_adaptor' do
      it 'should return bolt http' do
        expect(Neo4j::SessionManager.send(:cypher_session_adaptor, double, double,
                                          adaptor_class: Neo4j::Core::CypherSession::Adaptors::HTTP))
          .to be_a(Neo4j::Core::CypherSession::Adaptors::HTTP)
      end

      it 'should return bolt adapater' do
        allow_any_instance_of(Neo4j::Core::CypherSession::Adaptors::Bolt).to receive(:open_socket)
        expect(Neo4j::SessionManager.send(:cypher_session_adaptor, :bolt, ENV['NEO4J_BOLT_URL']))
          .to be_a(Neo4j::Core::CypherSession::Adaptors::Bolt)
      end
    end
  end
end
