# module ActiveGraph::Node::Scope

describe 'ActiveGraph::NodeMixin::Scope' do
  before do
    clear_model_memory_caches

    stub_node_class('Person') do
      property :name
      property :score
      property :level_num
      property :date_of_death
      has_many :out, :friends, type: nil, model_class: 'Person'

      scope :only_living, -> { where(date_of_death: nil) }
    end
  end

  before(:each) do
    @a = Person.create name: 'a', score: 42, level_num: 1
    @b = Person.create name: 'b', score: 42, level_num: 2
    @b1 = Person.create name: 'b1', score: 42, level_num: 3
    @b2 = Person.create name: 'b2', score: 42, level_num: 4

    @a.friends << @b
    @b.friends << @b1 << @b2
  end

  describe 'Inherited scope' do
    before do
      stub_named_class('Mutant', Person)
      stub_named_class('Sidekick', Mutant)
    end

    let!(:alive_mutant) { Mutant.create name: 'aa' }
    let!(:dead_mutant)  { Mutant.create name: 'bb', date_of_death: 'yesterday' }
    let!(:alive_sidekick) { Sidekick.create name: 'aa' }
    let!(:dead_sidekick)  { Sidekick.create name: 'bb', date_of_death: 'yesterday' }

    it 'has the scopes of the parent class' do
      expect(Mutant.scope?(:only_living)).to be true
      expect(Mutant.all.only_living.to_a).to contain_exactly(alive_mutant, alive_sidekick)
    end

    it 'has the scopes of the ancestor classes' do
      expect(Sidekick.scope?(:only_living)).to be true
      expect(Sidekick.all.only_living.to_a).to eq([alive_sidekick])
    end

    it 'inherits correctly overwritten scopes' do
      Mutant.scope :only_living, -> { where('1=0') }
      expect(Mutant.scope?(:only_living)).to be true
      expect(Mutant.all.only_living.to_a).to eq([])
      expect(Sidekick.scope?(:only_living)).to be true
      expect(Sidekick.all.only_living.to_a).to eq([])
    end
  end

  describe 'Person.scope :level, -> (num) { where(level: num)}' do
    before(:each) do
      Person.scope :level, ->(num) { where(level_num: num) }
    end

    describe 'Person.level(3)' do
      it 'returns person with level 3' do
        expect(Person.level(3).to_a).to eq([@b1])
      end
    end
  end

  describe 'Person.scope :in_order, ->(identifier) { order("#{identifier}.level_num DESC") }' do
    before(:each) do
      Person.scope :in_order, ->(identifier) { order("#{identifier}.level_num DESC") }
    end

    describe 'Person.in_order' do
      it 'returns person in order' do
        expect(Person.as(:people).in_order(:people).to_a).to eq([@b2, @b1, @b, @a])
      end
    end
  end

  describe 'Person.scope :in_order, -> { order("#{identity}.level_num DESC") }' do
    before(:each) do
      Person.scope :in_order, -> { order("#{identity}.level_num DESC") }
    end

    describe 'Person.in_order' do
      it 'returns person in order without explicit identifier' do
        expect(Person.in_order.to_a).to eq([@b2, @b1, @b, @a])
      end
    end
  end

  describe 'Person.scope :great_students, -> { where("#{identity}.score > 41")' do
    before(:each) do
      Person.scope :great_students, -> { where("#{identity}.score > 41") }
    end

    describe 'Person.top_students.to_a' do
      subject do
        Person.great_students.to_a
      end
      it { is_expected.to match_array([@a, @b, @b1, @b2]) }
    end
  end

  describe 'Person.scope :great_students, -> (identifier, score) { where("#{identifier}.score > ?", score)' do
    before(:each) do
      Person.scope :great_students, ->(identifier, score) { where("#{identifier}.score > ?", score || 41) }
    end

    describe 'Person.great_students.to_a' do
      subject do
        Person.as(:foo).great_students(:foo, 41).to_a
      end
      it { is_expected.to match_array([@a, @b, @b1, @b2]) }
    end

    describe 'Person.great_students.to_a with omitted parameter' do
      subject do
        Person.as(:foo).great_students(:foo).to_a
      end
      it { is_expected.to match_array([@a, @b, @b1, @b2]) }
    end
  end

  describe 'Person.scope :great_students, -> (identifier) { where("#{identifier}.score > 41")' do
    before(:each) do
      Person.scope :great_students, ->(identifier) { where("#{identifier}.score > 41") }
    end


    describe 'Person.top_students.to_a' do
      subject do
        Person.as(:foo).great_students(:foo).to_a
      end
      it { is_expected.to match_array([@a, @b, @b1, @b2]) }
    end
  end

  describe 'Person.scope :top_students, -> { where("score = ?", 42) }' do
    before(:each) do
      Person.scope :top_students, ->(name) { all(name || :tstud).where("#{name || :tstud}.score = ?", 42) }
    end

    it_behaves_like 'scopable model'

    describe 'person.top_students.top_students.to_a' do
      subject do
        Person.top_students(:tstud1).friends.top_students(:tstud2).to_a
      end
      it { is_expected.to match_array([@b, @b1, @b2]) }
    end
  end

  describe 'Person.scope :top_students, -> { where(score: 42) }' do
    before(:each) do
      Person.scope :top_students, -> { where(score: 42) }
    end

    it_behaves_like 'scopable model'
    it_behaves_like 'chained scopable model'
  end

  describe 'Person.scope :top_students, -> { another_scope }' do
    before(:each) do
      Person.scope :another_scope, -> { where(score: 42) }
      Person.scope :top_students, -> { another_scope }
    end

    it_behaves_like 'scopable model'
    it_behaves_like 'chained scopable model'
  end

  describe 'Person.scope :top_friends, -> { friends.where(score: 42) }' do
    before(:each) do
      Person.scope :top_friends, -> { friends.where(score: 42) }
    end

    describe 'Person.top_friends.to_a' do
      subject do
        Person.top_friends
      end

      it { is_expected.to match_array([@b, @b1, @b2]) }
    end

    describe 'person.top_friends.to_a' do
      subject do
        @a.top_friends
      end

      it { is_expected.to match_array([@b]) }
    end
  end

  describe 'Person.scope :having_friends_being_top_students, -> { all(:p).friends(:f).where(score: 42).query_as(Person, :p) }' do
    before(:each) do
      Person.scope :having_friends_being_top_students, -> { all(:p).branch { friends(:f).where(score: 42) } }
    end

    describe 'Person.having_friends_being_top_students.to_a' do
      subject do
        Person.having_friends_being_top_students
      end

      it { is_expected.to match_array([@a, @b, @b]) }
    end
  end
end
