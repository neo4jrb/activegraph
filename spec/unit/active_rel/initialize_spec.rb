describe ActiveGraph::Relationship::Initialize do
  let(:clazz) do
    Class.new do
      include ActiveGraph::Relationship::Initialize
    end
  end

  describe 'init_on_load'
  describe 'wrapper' do
    it 'returns self' do
      r = clazz.new
      expect(r.wrapper).to eq r
    end
  end
end
