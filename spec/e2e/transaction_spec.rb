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
    before(:each) do
      stub_active_node_class('Clazz') do
        property :name
        validates :name, presence: true
      end
    end

    it 'rollbacks the current transaction by default' do
      expect do
        Neo4j::Transaction.run do |tx|
          Clazz.create
          expect(tx).to be_failed
          Clazz.create(name: 'john')
        end
      end.not_to change { Clazz.count }
    end

    context 'when `fail_transaction_when_validations_fail` is disabled' do
      let_config(:fail_transaction_when_validations_fail) { false }

      it 'keeps running the current transaction' do
        expect do
          Neo4j::Transaction.run do |tx|
            Clazz.create
            expect(tx).not_to be_failed
            Clazz.create(name: 'john')
          end
        end.to change { Clazz.count }.by(1)
        Neo4j::Config.delete(:fail_transaction_when_validations_fail)
      end
    end
  end
end
