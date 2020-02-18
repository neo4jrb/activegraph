describe ActiveGraph::Config do
  describe 'default_file' do
    it 'should exist' do
      expect(File.exist?(ActiveGraph::Config.default_file)).to eq(true)
    end
  end

  describe 'when using a different existing config' do
    before do
      ActiveGraph::Config.default_file = File.expand_path(File.join(File.dirname(__FILE__), 'config.yml'))
    end

    after do
      ActiveGraph::Config.default_file = ActiveGraph::Config::DEFAULT_FILE
    end

    describe 'defaults' do
      it 'has values' do
        expect(ActiveGraph::Config.defaults[:my_conf]).to eq('My value')
      end
    end

    describe '[]' do
      it 'returns the configuration property' do
        expect(ActiveGraph::Config[:my_conf]).to eq('My value')
      end
    end

    describe '[]=' do
      it 'can set new configuration' do
        ActiveGraph::Config[:foo] = 42
        ActiveGraph::Config[:my_conf] = 43
        expect(ActiveGraph::Config[:foo]).to eq(42)
        expect(ActiveGraph::Config[:my_conf]).to eq(43)
      end

      it 'can use both strings and symbols as keys' do
        ActiveGraph::Config[:foo] = 1
        ActiveGraph::Config['bar'] = 2
        expect(ActiveGraph::Config[:foo]).to eq(1)
        expect(ActiveGraph::Config['bar']).to eq(2)
        expect(ActiveGraph::Config['foo']).to eq(1)
        expect(ActiveGraph::Config[:bar]).to eq(2)
      end
    end

    describe 'delete' do
      it 'deletes a configuration' do
        expect(ActiveGraph::Config[:my_conf]).to eq('My value')
        ActiveGraph::Config.delete(:my_conf)
        expect(ActiveGraph::Config[:my_conf]).to be_nil
      end
    end


    describe 'use' do
      it 'yields the configuration' do
        ActiveGraph::Config.use do |c|
          c[:bar] = 'foo'
        end
        expect(ActiveGraph::Config[:bar]).to eq('foo')
      end
    end

    describe 'to_yaml' do
      it 'returns yaml string' do
        expect(ActiveGraph::Config.to_yaml).to match(/my_conf: My value/)
      end
    end

    describe 'to_hash' do
      it 'returns hash' do
        expect(ActiveGraph::Config.to_hash).to be_a(Hash)
        expect(ActiveGraph::Config.to_hash['my_conf']).to eq('My value')
      end
    end

    describe 'delete_all' do
      it 'deletes all' do
        ActiveGraph::Config.delete_all
        expect(ActiveGraph::Config.configuration).to eq('my_conf' => 'My value')
      end
    end
  end

  describe 'options' do
    describe 'include_root_in_json' do
      it 'defaults to true' do
        expect(ActiveGraph::Config.include_root_in_json).to be_truthy
      end

      it 'respects config' do
        ActiveGraph::Config[:include_root_in_json] = false
        expect(ActiveGraph::Config.include_root_in_json).to be_falsey
      end
    end

    describe 'timestamp_type' do
      after(:all) { ActiveGraph::Config[:timestamp_type] = nil }
      it 'defaults to DateTime' do
        expect(ActiveGraph::Config.timestamp_type).to eq(DateTime)
      end

      it 'respects config' do
        ActiveGraph::Config[:timestamp_type] = Integer
        expect(ActiveGraph::Config.timestamp_type).to eq(Integer)
      end
    end
  end
end
