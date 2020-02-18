# frozen_string_literal: true

describe ActiveGraph::AttributeSet do
  let(:attr_hash) { {halley: 1986} }
  let(:attr_list) { [:halley, :icarus_year] }
  subject { ActiveGraph::AttributeSet.new(attr_hash, attr_list) }

  describe '#method_missing' do
    let(:delegated_hash) { subject.instance_variable_get(:@attributes).send(:materialize) }

    it 'delegates method_missing to attribute Hash' do
      expect(delegated_hash).to receive(:key?).with('name')
      subject.key?('name')
    end

    it 'delegates keyword arguments to attribute Hash' do
      expect(delegated_hash).to receive(:merge).with(icarus_year: 1566)
      subject.merge(icarus_year: 1566)
    end

    it 'delegates block to attribute Hash' do
      called = false
      block = ->(_) { called = true }
      expect(delegated_hash).to receive(:fetch_values).and_call_original
      subject.fetch_values(false, &block)
      expect(called).to be true
    end
  end

  describe 'marshalling' do
    it 'marshal dump and loads correctly' do
      marshalled_obj = Marshal.load(Marshal.dump(subject))
      expect(subject).to eq(marshalled_obj)
    end
  end

  describe 'equality' do
    it "doesn't error while comparing with hash" do
      allow(subject).to receive(:to_hash) { attr_hash }
      expect(attr_hash == subject).to be true
    end
  end
end
