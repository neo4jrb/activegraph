module ActiveGraph::Node
  describe NodeListFormatter do
    let(:max_elements) { 5 }

    subject { described_class.new(list, max_elements) }

    context 'when the list length is greater than `max_elements`' do
      let(:list) { (0...10).to_a }

      its(:inspect) { is_expected.to eq '[0, 1, 2, 3, 4, ...]' }
    end

    context 'when the list length is less or equal than `max_elements`' do
      let(:list) { (0...5).to_a }

      its(:inspect) { is_expected.to eq '[0, 1, 2, 3, 4]' }
    end
  end
end
