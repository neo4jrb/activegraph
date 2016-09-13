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
      let(:cfg) do
        ActiveSupport::OrderedOptions.new.tap do |c|
          c.session = ActiveSupport::OrderedOptions.new
          c.session.path = session_path if session_path
        end
      end

      before do
        stub_const('Neo4j::SessionManager', spy('Neo4j::SessionManager'))

        Neo4j::Railtie.setup!(cfg)
      end

      let_context(session_path: 'http://user:password@localhost:7474') do
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
        subject_should_raise(ArgumentError, /Invalid session type: :invalid_type$/)
      end

      let_context(session_type: :server_db) do
        subject_should_raise(ArgumentError, /Invalid session type: :server_db \(`server_db` has been replaced/)
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
  end
end
