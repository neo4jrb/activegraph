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

  describe 'transaction behaviour when a validation fails' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        validates :name, presence: true
      end
    end

    it 'rollbacks the current transaction' do
      expect do
        Neo4j::Transaction.run do |tx|
          clazz.create
          expect(tx).to be_failed
          clazz.create(name: 'john')
        end
      end.not_to change { clazz.count }
    end

    it 'rollbacks the current transaction' do
      Neo4j::Config[:fail_transaction_when_validations_fail] = false

      expect do
        Neo4j::Transaction.run do |tx|
          clazz.create
          expect(tx).not_to be_failed
          clazz.create(name: 'john')
        end
      end.to change { clazz.count }.by(1)
      Neo4j::Config.delete(:fail_transaction_when_validations_fail)
    end
  end
end
