# tests = Proc.new do
describe 'Labels' do
  before(:all) do
    @prev_wrapped_classes = Neo4j::ActiveNode::Labels._wrapped_classes
    Neo4j::ActiveNode::Labels._wrapped_classes.clear

    class TestClass
      include Neo4j::ActiveNode
    end

    Neo4j::Label.create(:IndexedTestClass).drop_index(:name)

    class IndexedTestClass
      include Neo4j::ActiveNode
      property :name
      index :name # will index using the IndexedTestClass label
    end

    module SomeLabelMixin
      def self.mapped_label_name
        :some_label
      end

      def self.neo4j_session
        Neo4j::Session.current
      end

      extend Neo4j::ActiveNode::Query::ClassMethods
      extend Neo4j::ActiveNode::Labels::ClassMethods
    end

    class SomeLabelClass
      include Neo4j::ActiveNode
      include SomeLabelMixin
    end

    class RelationTestClass
      include Neo4j::ActiveNode

      has_one :in, :test_class, type: nil
    end
  end


  after(:all) do
    Neo4j::ActiveNode::Labels._wrapped_classes.concat(@prev_wrapped_classes)
    Object.send(:remove_const, :IndexedTestClass)
    Object.send(:remove_const, :TestClass)
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
        result = IndexedTestClass.all
        expect(result).to include(jimmy)
        jimmy.destroy
        expect(IndexedTestClass.all).not_to include(jimmy)
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
    before(:all) { @jasmine = IndexedTestClass.create(name: 'jasmine') }

    describe 'find_by' do
      it 'finds the expected object' do
        expect(IndexedTestClass.find_by(name: 'jasmine')).to eq @jasmine
      end

      it 'returns nil if no results match' do
        expect(IndexedTestClass.find_by(name: 'foo')).to eq nil
      end
    end

    describe 'find_by!' do
      it 'finds the expected object' do
        expect(IndexedTestClass.find_by!(name: 'jasmine')).to eq @jasmine
      end

      it 'raises an error if no results match' do
        expect { IndexedTestClass.find_by!(name: 'foo') }.to raise_exception Neo4j::ActiveNode::Labels::RecordNotFound
      end
    end
  end

  describe 'first and last' do
    before(:all) do
      class FirstLastTestClass
        include Neo4j::ActiveNode
        property :name
      end

      class EmptyTestClass
        include Neo4j::ActiveNode
      end

      @jasmine = FirstLastTestClass.create(name: 'jasmine')
      @middle = FirstLastTestClass.create
      @lauren = FirstLastTestClass.create(name: 'lauren')
    end

    describe 'first' do
      it 'returns the first object created... sort of, see docs' do
        expect(FirstLastTestClass.first).to eq [@jasmine, @middle, @lauren].sort_by(&:uuid).first
      end
    end

    describe 'last' do
      it 'returns the last object created... sort of, see docs' do
        expect(FirstLastTestClass.last).to eq [@jasmine, @middle, @lauren].sort_by(&:uuid).last
      end

      it 'returns nil when there are no results' do
        expect(EmptyTestClass.last).to eq nil
      end
    end
  end
end

# shared_examples_for 'Neo4j::ActiveNode with Mixin Index'do
#  before(:all) do
#    Neo4j::ActiveNode::Labels._wrapped_classes = []
#    Neo4j::ActiveNode::Labels._wrapped_labels = nil
#
#    Neo4j::Label.create(:BarIndexedLabel).drop_index(:baaz)
#    sleep(1) # to make it possible to search using this module (?)
#
#    module BarIndexedLabel
#      extend Neo4j::ActiveNode::Labels::ClassMethods # to make it possible to search using this module (?)
#      begin
#        index :baaz
#      rescue => e
#        puts "WARNING: sometimes neo4j has a problem with removing and adding indexes in tests #{e}" # TODO
#      end
#    end
#
#    class TestClassWithBar
#      include Neo4j::ActiveNode
#      include BarIndexedLabel
#    end
#  end
#
#
#  it "can be found using the Mixin Module" do
#    hej = TestClassWithBar.create(:baaz => 'hej')
#    BarIndexedLabel.find(:baaz, 'hej').should include(hej)
#    TestClassWithBar.find(:baaz, 'hej').should include(hej)
#    BarIndexedLabel.find(:baaz, 'hej2').should_not include(hej)
#    TestClassWithBar.find(:baaz, 'hej2').should_not include(hej)
#  end
# end

# describe 'Neo4j::ActiveNode, server', api: :server do
#  it_behaves_like 'Neo4j::ActiveNode'
#  it_behaves_like "Neo4j::ActiveNode with Mixin Index"
# end
#
# describe 'Neo4j::ActiveNode, embedded', api: :embedded do
#  it_behaves_like 'Neo4j::ActiveNode'
#  it_behaves_like "Neo4j::ActiveNode with Mixin Index"
# end
