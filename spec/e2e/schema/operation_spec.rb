module Neo4j::Schema
  describe 'operation classes' do
    it_behaves_like 'schema operation create/drop', ExactIndexOperation, UniqueConstraintOperation
    it_behaves_like 'schema operation create/drop', UniqueConstraintOperation, ExactIndexOperation
  end
end
