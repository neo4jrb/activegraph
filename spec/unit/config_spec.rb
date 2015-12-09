describe Neo4j::Config do
  describe 'default_file' do
    it 'should exist' do
      expect(File.exist?(Neo4j::Config.default_file)).to eq(true)
    end
  end

  describe 'when using a different existing config' do
    before do
      Neo4j::Config.default_file = File.expand_path(File.join(File.dirname(__FILE__), 'config.yml'))
    end

    after do
      Neo4j::Config.default_file = Neo4j::Config::DEFAULT_FILE
    end

    describe 'defaults' do
      it 'has values' do
        expect(Neo4j::Config.defaults[:my_conf]).to eq('My value')
      end
    end

    describe '[]' do
      it 'returns the configuration property' do
        expect(Neo4j::Config[:my_conf]).to eq('My value')
      end
    end

    describe '[]=' do
      it 'can set new configuration' do
        Neo4j::Config[:foo] = 42
        Neo4j::Config[:my_conf] = 43
        expect(Neo4j::Config[:foo]).to eq(42)
        expect(Neo4j::Config[:my_conf]).to eq(43)
      end

      it 'can use both strings and symbols as keys' do
        Neo4j::Config[:foo] = 1
        Neo4j::Config['bar'] = 2
        expect(Neo4j::Config[:foo]).to eq(1)
        expect(Neo4j::Config['bar']).to eq(2)
        expect(Neo4j::Config['foo']).to eq(1)
        expect(Neo4j::Config[:bar]).to eq(2)
      end
    end

    describe 'delete' do
      it 'deletes a configuration' do
        expect(Neo4j::Config[:my_conf]).to eq('My value')
        Neo4j::Config.delete(:my_conf)
        expect(Neo4j::Config[:my_conf]).to be_nil
      end
    end


    describe 'use' do
      it 'yields the configuration' do
        Neo4j::Config.use do |c|
          c[:bar] = 'foo'
        end
        expect(Neo4j::Config[:bar]).to eq('foo')
      end
    end

    describe 'to_yaml' do
      it 'returns yaml string' do
        expect(Neo4j::Config.to_yaml).to match(/my_conf: My value/)
      end
    end

    describe 'to_hash' do
      it 'returns hash' do
        expect(Neo4j::Config.to_hash).to be_a(Hash)
        expect(Neo4j::Config.to_hash['my_conf']).to eq('My value')
      end
    end

    describe 'delete_all' do
      it 'deletes all' do
        Neo4j::Config.delete_all
        expect(Neo4j::Config.configuration).to eq('my_conf' => 'My value')
      end
    end
  end

  describe 'options' do
    describe 'include_root_in_json' do
      it 'defaults to true' do
        expect(Neo4j::Config.include_root_in_json).to be_truthy
      end

      it 'respects config' do
        Neo4j::Config[:include_root_in_json] = false
        expect(Neo4j::Config.include_root_in_json).to be_falsey
      end
    end

    describe 'timestamp_type' do
      after(:all) { Neo4j::Config[:timestamp_type] = nil }
      it 'defaults to DateTime' do
        expect(Neo4j::Config.timestamp_type).to eq(DateTime)
      end

      it 'respects config' do
        Neo4j::Config[:timestamp_type] = Integer
        expect(Neo4j::Config.timestamp_type).to eq(Integer)
      end
    end
  end
end
