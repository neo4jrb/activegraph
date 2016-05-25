# module Neo4j::ActiveNode::Scope

describe 'Neo4j::NodeMixin::Scope' do
  before(:each) do
    clear_model_memory_caches

    stub_active_node_class('Person') do
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

  after(:each) do
    delete_db
  end

  describe 'Inherited scope' do
    before { stub_named_class('Mutant', Person) }

    let!(:alive) { Mutant.create name: 'aa' }
    let!(:dead)  { Mutant.create name: 'bb', date_of_death: 'yesterday' }

    it 'has the scope of the parent class' do
      expect(Mutant.scope?(:only_living)).to be true
      expect(Mutant.all.only_living.to_a).to eq([alive])
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

  describe 'Person.scope :in_order, -> { order(level: num)}' do
    before(:each) do
      Person.scope :in_order, ->(identifier) { order("#{identifier}.level_num DESC") }
    end

    describe 'Person.in_order' do
      it 'returns person in order' do
        expect(Person.as(:people).in_order(:people).to_a).to eq([@b2, @b1, @b, @a])
      end
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

  describe 'Person.scope :top_students, -> { where(score: 42)}' do
    before(:each) do
      Person.scope :top_students, -> { where(score: 42) }
    end


    describe 'Person.top_students.to_a' do
      subject do
        Person.top_students.to_a
      end
      it { is_expected.to match_array([@a, @b, @b1, @b2]) }
    end

    describe 'person.friends.top_students.to_a' do
      subject do
        @a.friends.top_students.to_a
      end
      it { is_expected.to match_array([@b]) }
    end

    describe 'person.friends.friend.top_students.to_a' do
      subject do
        @a.friends.friends.top_students.to_a
      end
      it { is_expected.to match_array([@b1, @b2]) }
    end

    describe 'person.top_students.friends.to_a' do
      subject do
        @a.friends.top_students.friends.to_a
      end
      it { is_expected.to match_array([@b1, @b2]) }
    end

    describe 'person.top_students.top_students.to_a' do
      subject do
        Person.top_students.friends.top_students.to_a
      end
      it { is_expected.to match_array([@b, @b1, @b2]) }
    end
  end
  # end
end
