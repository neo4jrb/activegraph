require 'spec_helper'

# module Neo4j::ActiveNode::Scope

describe 'Neo4j::NodeMixin::Scope' do
  class Person
    include Neo4j::ActiveNode
    property :name
    property :score
    property :level_num
    has_many :out, :friends, model_class: self
  end

  before(:all) do
    @a = Person.create name: 'a', score: 42, level_num: 1
    @b = Person.create name: 'b', score: 42, level_num: 2
    @b1 = Person.create name: 'b1', score: 42, level_num: 3
    @b2 = Person.create name: 'b2', score: 42, level_num: 4

    @a.friends << @b
    @b.friends << @b1 << @b2
  end


  describe 'Person.scope :level, -> (num) { where(level: num)}' do
    before(:all) do
      Person.scope :level, ->(num) { where(level_num: num) }
    end

    describe 'Person.level(3)' do
      it 'returns person with level 3' do
        expect(Person.level(3).to_a).to eq([@b1])
      end
    end
  end

  describe 'Person.scope :in_order, -> { order(level: num)}' do
    before(:all) do
      Person.scope :in_order, ->(identifier) { order("#{identifier}.level_num DESC") }
    end

    describe 'Person.in_order' do
      it 'returns person in order' do
        expect(Person.as(:people).in_order(:people).to_a).to eq([@b2, @b1, @b, @a])
      end
    end
  end

  describe 'Person.scope :great_students, -> (identifier) { where("#{identifier}.score > 41")' do
    before(:all) do
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
    before(:all) do
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
