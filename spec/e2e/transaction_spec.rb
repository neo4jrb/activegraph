describe 'Neo4j::Transaction' do
  context 'reading has_one relationships for Neo4j::Server' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        has_one :out, :thing, type: nil, model_class: self
      end
    end

    before { clazz }

    it 'returns a wrapped node inside and outside of transaction' do
      begin
        tx = Neo4j::Transaction.new
        a = clazz.create name: 'a'
        b = clazz.create name: 'b'
        a.thing = b
        expect(a.thing).to eq b
      ensure
        tx.close
      end
      expect(a.thing).to eq(b)
    end
  end
end
