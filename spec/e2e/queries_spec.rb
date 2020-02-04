describe 'Neo4j::ActiveNode#find' do
  before do
    clear_model_memory_caches
  end

  let(:clazz) do
    stub_active_node_class('Clazz') do
      property :name
    end
  end

  it 'can find nodes that exists' do
    foo = clazz.create(name: 'foo')
    expect(clazz.where(name: 'foo').first).to eq(foo)
  end

  it 'can not find nodes that does not exists' do
    expect(clazz.where(name: 'unkown').first).to be_nil
  end
end


describe 'Neo4j::ActiveNode#all' do
  before do
    clear_model_memory_caches
  end

  before do
    stub_active_node_class('ClazzA') do
      property :name
      property :score, type: Integer

      has_one :out, :knows, type: nil, model_class: false
    end

    stub_active_node_class('ClazzB') do
      property :name
      property :score, type: Integer

      has_many :in, :known_by, type: nil, model_class: false
    end
  end

  let!(:b2) { ClazzB.create(name: 'b2', score: '2') }
  let!(:b1) { ClazzB.create(name: 'b1', score: '1') }

  let!(:a2) { ClazzA.create(name: 'b2', score: '2', knows: b2) }
  let!(:a1) { ClazzA.create(name: 'b1', score: '1', knows: b1) }
  let!(:a4) { ClazzA.create(name: 'b4', score: '4', knows: b1) }
  let!(:a3) { ClazzA.create(name: 'b3', score: '3', knows: b2) }

  it 'can find nodes that exists' do
    expect(ClazzA.where(score: 1).to_a).to match_array([a1])
  end

  it 'can sort them' do
    expect(ClazzA.order(:score).to_a).to eq([a1, a2, a3, a4])
  end

  it 'can skip and limit result' do
    expect(ClazzA.order(:score).skip(1).limit(2).to_a).to eq([a2, a3])
  end

  it 'can find all nodes having a relationship to another node' do
    expect(b2.known_by.to_a).to match_array([a3, a2])
  end

  it 'can not find all nodes having a relationship to another node if there are non' do
    expect(ClazzB.query_as(:b).match('(b)<-[:knows]-(r)').pluck(:r)).to eq([])
  end
end
