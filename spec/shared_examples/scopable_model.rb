shared_examples_for 'scopable model' do
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
end


shared_examples_for 'chained scopable model' do
  describe 'person.top_students.top_students.to_a' do
    subject do
      Person.top_students.friends.top_students.to_a
    end
    it { is_expected.to match_array([@b, @b1, @b2]) }
  end
end
