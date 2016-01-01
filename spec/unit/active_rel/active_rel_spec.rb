describe Neo4j::ActiveRel do
  let(:clazz) do
    Class.new do
      def self.name
        'Clazz'
      end

      include Neo4j::ActiveRel
    end
  end

  it 'can be included in a module' do
    expect { clazz.new }.not_to raise_error
  end

  describe 'neo4j_obj' do
    context 'on a non-persisted node' do
      it 'raises an error' do
        expect { clazz.new.neo4j_obj }.to raise_error(/Tried to access native neo4j object on a non persisted object/)
      end
    end
  end
end
