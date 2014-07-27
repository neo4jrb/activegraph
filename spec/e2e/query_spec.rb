require 'spec_helper'
require 'set'
class Student; end
class Teacher; end

class Interest
  include Neo4j::ActiveNode

  property :name

  has_many :both, :interested, model_class: false
end

class Lesson
  include Neo4j::ActiveNode
  property :subject
  property :level

  has_many :in, :teachers, type: :teaching
  has_many :in, :students, type: :is_enrolled_for

  def self.max_level
    self.query_as(:lesson).pluck('max(lesson.level)').first
  end

  def self.level(num)
    self.where(level: num)
  end
end

class Student
  include Neo4j::ActiveNode
  property :name
  property :age, type: Integer

  has_many :out, :lessons, type: :is_enrolled_for

  has_many :out, :interests

  has_many :both, :favorite_teachers, model_class: Teacher
  has_many :both, :hated_teachers, model_class: Teacher
end

class Teacher
  include Neo4j::ActiveNode
  property :name

  has_many :both, :lessons

  has_many :out, :lessons_teaching, model_class: Lesson
  has_many :out, :lessons_taught, model_class: Lesson

  has_many :out, :interests
end

describe 'Query API' do
  before(:each) { delete_db }
  describe 'queries directly on a model class' do
    let!(:samuels) { Teacher.create(name: 'Harold Samuels') }
    let!(:othmar) { Teacher.create(name: 'Ms. Othmar') }

    let!(:ss101) { Lesson.create(subject: 'Social Studies', level: 101) }
    let!(:ss102) { Lesson.create(subject: 'Social Studies', level: 102) }
    let!(:math101) { Lesson.create(subject: 'Math', level: 101) }
    let!(:math201) { Lesson.create(subject: 'Math', level: 201) }
    let!(:geo103) { Lesson.create(subject: 'Geography', level: 103) }

    let!(:sandra) { Student.create(name: 'Sandra', age: 16) }
    let!(:danny) { Student.create(name: 'Danny', age: 15) }
    let!(:bobby) { Student.create(name: 'Bobby', age: 16) }
    let!(:brian) { Student.create(name: 'Bobby', age: 25) }

    let!(:reading) { Interest.create(name: 'Reading') }
    let!(:math) { Interest.create(name: 'Math') }
    let!(:monster_trucks) { Interest.create(name: 'Monster Trucks') }

    it 'returns all' do
      result = Teacher.to_a

      result.size.should == 2
      result.should include(samuels)
      result.should include(othmar)
    end

    it 'allows filtering' do
      Teacher.where(name: /.*Othmar.*/).to_a.should == [othmar]
    end

    context 'samuels teaching soc 101 and 102 lessons' do
      before(:each) do
        samuels.lessons_teaching << ss101
        samuels.lessons_teaching << ss102
      end

      it 'allows definining of a variable for class as start of QueryProxy chain' do
        Teacher.as(:t).lessons.where(level: 101).pluck(:t).should == [samuels]
      end

      context 'samuels taught math 101 lesson' do
        before(:each) { samuels.lessons_taught << math101 }

        it 'returns only objects specified by association' do
          samuels.lessons_teaching.to_set.should == [ss101, ss102].to_set

          samuels.lessons.to_set.should == [ss101, ss102, math101].to_set
        end
      end
    end

    context 'bobby has teacher preferences' do
      before(:each) do
        bobby.favorite_teachers << samuels
        bobby.hated_teachers << othmar
      end

      it 'differentiates associations on the same model for the same class' do
        bobby.favorite_teachers.to_set.should == [samuels].to_set
        bobby.hated_teachers.to_set.should == [othmar].to_set
      end
    end

    context 'samuels is teaching soc 101 and geo 103' do
      before(:each) do
        samuels.lessons_teaching << ss101
        samuels.lessons_teaching << geo103
      end

      it 'allows params' do
        Teacher.as(:t).where("t.name = {name}").params(name: 'Harold Samuels').to_a.should == [samuels]

        samuels.lessons_teaching(:lesson).where("lesson.level = {level}").params(level: 103).to_a.should == [geo103]
        samuels.lessons_teaching.where(level: "{level}").params(level: 103).to_a.should == [geo103]
      end

      it 'allows filtering on associations' do
        samuels.lessons_teaching.where(level: 101).to_a.should == [ss101]
      end

      it 'allows class methods on associations' do
        samuels.lessons_teaching.level(101).to_a.should == [ss101]

        samuels.lessons_teaching.max_level.should == 103
        samuels.lessons_teaching.where(subject: 'Social Studies').max_level.should == 101
      end
    end

    describe 'association chaining' do
      context 'othmar is teaching math 101' do
        before(:each) { othmar.lessons_teaching << math101 }

        context 'bobby is taking math 101, sandra is taking soc 101' do
          before(:each) { bobby.lessons << math101 }
          before(:each) { sandra.lessons << ss101 }

          it { othmar.lessons_teaching.students.to_a.should == [bobby] }

          context 'bobby likes to read, sandra likes math' do
            before(:each) { bobby.interests << reading }
            before(:each) { sandra.interests << math }

            # Simple association chaining on three levels
            it { othmar.lessons_teaching.students.interests.to_a.should == [reading] }
          end
        end

        context 'danny is also taking math 101' do
          before(:each) { danny.lessons << math101 }

          # Filtering on last association
          it { othmar.lessons_teaching.students.where(age: 15).to_a.should == [danny] }

          # Mid-association variable assignment when filtering later
          it { othmar.lessons_teaching(:lesson).students.where(age: 15).pluck(:lesson).should == [math101] }

          # Two variable assignments
          it { othmar.lessons_teaching(:lesson).students(:student).where(age: 15).pluck(:lesson, :student).should == [[math101, danny]] }
        end
      end

      context 'othmar is also teaching math 201, brian is taking it' do
        before(:each) { othmar.lessons_teaching << math201 }
        before(:each) { brian.lessons << math201 }

        # Mid-association filtering
        it { othmar.lessons_teaching.where(level: 201).students.to_a.should == [brian] }
      end
    end

    context 'othmar likes moster trucks more than samuels' do
      before(:each) do
        samuels.interests.associate(monster_trucks, intensity: 1)
        othmar.interests.associate(monster_trucks, intensity: 11)
      end

      # Should get both
      it { monster_trucks.interested.to_set.should == [samuels, othmar].to_set }

      # Variable assignment and filtering on a relationship
      it { monster_trucks.interested(:person, :r).where('r.intensity < 5').pluck(:person).should == [samuels] }
    end
  end
end

