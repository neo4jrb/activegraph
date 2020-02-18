# tests = Proc.new do
describe 'Labels' do
  before do
    clear_model_memory_caches

    stub_active_node_class('TestClass')

    create_index :IndexedTestClass, :name, type: :exact
    stub_active_node_class('IndexedTestClass') do
      property :name
    end

    module SomeLabelMixin
      def self.mapped_label_name
        :some_label
      end

      def self.neo4j_driver
        current_driver
      end

      extend ActiveGraph::ActiveNode::Query::ClassMethods
      extend ActiveGraph::ActiveNode::Labels::ClassMethods
    end

    stub_active_node_class('SomeLabelClass') do
      include SomeLabelMixin
    end

    stub_active_node_class('RelationTestClass') do
      has_one :in, :test_class, type: nil
    end
  end

  describe 'create' do
    it 'automatically sets a label' do
      p = TestClass.create
      expect(p.labels.to_a).to eq([:TestClass])
    end

    it 'sets label for mixin classes' do
      p = SomeLabelClass.create
      expect(p.labels.to_a).to match_array([:SomeLabelClass, :some_label])
    end
  end

  describe 'all' do
    it 'finds it without an index' do
      p = TestClass.create
      expect(TestClass.all.to_a).to include(p)
    end

    describe 'when indexed' do
      it 'can find it without using the index' do
        andreas = IndexedTestClass.create(name: 'andreas')
        result = IndexedTestClass.all
        expect(result).to include(andreas)
      end

      it 'does not find it if it has been deleted' do
        jimmy = IndexedTestClass.create(name: 'jimmy')
        result = IndexedTestClass.all.to_a
        expect(result).to include(jimmy)
        jimmy.destroy
        expect(IndexedTestClass.all.to_a).not_to include(jimmy)
      end
    end

    it 'allows changing of the node identifier' do
      expect(TestClass.all.query_as(:id_test).to_cypher).to include 'id_test'
    end
  end

  describe 'find' do
    it 'finds it without an index' do
      p = TestClass.create
      expect(TestClass.all.to_a).to include(p)
    end

    describe 'when indexed' do
      it 'can find it using the index' do
        IndexedTestClass.delete_all
        kalle = IndexedTestClass.create(name: 'kalle')
        expect(IndexedTestClass.where(name: 'kalle').first).to eq(kalle)
      end

      it 'does not find it if deleted' do
        IndexedTestClass.delete_all
        kalle2 = IndexedTestClass.create(name: 'kalle2')
        result = IndexedTestClass.where(name: 'kalle2').first
        expect(result).to eq(kalle2)
        kalle2.destroy
        expect(IndexedTestClass.where(name: 'kalle2')).not_to include(kalle2)
      end
    end

    context 'a relationship' do
      let!(:n1) { TestClass.create }
      let!(:n2) { RelationTestClass.create(test_class: n1) }

      it 'finds when association matches' do
        expect(RelationTestClass.where(test_class: n1).first).to eq(n2)
      end

      it 'does not find when association does not match' do
        expect(RelationTestClass.where(test_class: n2).first).to be_nil
      end
    end
  end

  describe 'find_by, find_by!' do
    let!(:jasmine) { IndexedTestClass.create(name: 'jasmine') }

    describe 'find_by' do
      it 'finds the expected object' do
        expect(IndexedTestClass.find_by(name: 'jasmine')).to eq jasmine
      end

      it 'returns nil if no results match' do
        expect(IndexedTestClass.find_by(name: 'foo')).to eq nil
      end
    end

    describe 'find_by!' do
      it 'finds the expected object' do
        expect(IndexedTestClass.find_by!(name: 'jasmine')).to eq jasmine
      end

      it 'raises an error if no results match' do
        expect { IndexedTestClass.find_by!(name: 'foo') }
          .to raise_error(ActiveGraph::ActiveNode::Labels::RecordNotFound) { |e| expect(e.model).to eq 'IndexedTestClass' }
      end
    end
  end

  describe 'first and last' do
    before do
      stub_active_node_class('FirstLastTestClass') do
        property :name
      end

      stub_active_node_class('EmptyTestClass')

      @jasmine = FirstLastTestClass.create(name: 'jasmine')
      @middle = FirstLastTestClass.create
      @lauren = FirstLastTestClass.create(name: 'lauren')
    end

    describe 'first' do
      it 'returns the first object created... sort of, see docs' do
        expect(FirstLastTestClass.first).to eq [@jasmine, @middle, @lauren].min_by(&:id)
      end
    end

    describe 'last' do
      it 'returns the last object created... sort of, see docs' do
        expect(FirstLastTestClass.last).to eq [@jasmine, @middle, @lauren].max_by(&:id)
      end

      it 'returns nil when there are no results' do
        expect(EmptyTestClass.last).to eq nil
      end
    end
  end
end
