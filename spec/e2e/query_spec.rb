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

  has_one  :out, :teachers_pet, model_class: Student, type: 'favorite_student'
  has_many :in, :unhappy_teachers, model_class: Teacher, origin: :dreaded_lesson
  has_many :in, :teachers, type: :teaching
  has_many :in, :students, type: :is_enrolled_for

  def self.max_level(num=nil)
    all.query_as(:lesson).pluck('max(lesson.level)').first
  end

  def self.ordered_by_subject
    all.order(:subject)
  end

  scope :level_number, ->(num) { where(level: num)}
end

class Student
  include Neo4j::ActiveNode
  property :name
  property :age, type: Integer

  has_many :out, :lessons, type: :is_enrolled_for

  has_many :out, :interests

  has_many :both, :favorite_teachers, model_class: Teacher
  has_many :both, :hated_teachers, model_class: Teacher
  has_many :in,   :winning_lessons, model_class: Lesson, origin: :teachers_pet
end

class Teacher
  include Neo4j::ActiveNode
  property :name

  has_many :both, :lessons

  has_many :out, :lessons_teaching, model_class: Lesson
  has_many :out, :lessons_taught, model_class: Lesson

  has_many :out, :interests
  has_one  :out, :dreaded_lesson, model_class: Lesson, type: 'least_favorite_lesson'
end

describe 'Query API' do
  before(:each) { delete_db }

  describe 'association validation' do
    before(:each) do
      %w{Foo Bar}.each do |const|
        stub_const const, Class.new { include Neo4j::ActiveNode }
      end
    end

    context 'Foo has an association to Bar' do
      before(:each) do
        Foo.has_many :in, :bars, model_class: Bar
      end

      subject { Bar.create }

      context 'other class is opposite direction' do
        before(:each) { Bar.has_many :out, :foos, origin: :bars }

        it { expect { subject.foos.to_a }.not_to raise_error }
      end

      context 'other class is both' do
        before(:each) { Bar.has_many :both, :foos, origin: :bars }

        it { expect { subject.foos.to_a }.not_to raise_error }
      end

      context 'Assumed model does not exist' do
        before(:each) { Bar.has_many :out, :foosrs, origin: :bars }

        it { expect { subject.foosrs.to_a }.to raise_error(NameError) }
      end

      context 'Specified model does not exist' do
        before(:each) { Bar.has_many :out, :foosrs, model_class: 'Foosrs', origin: :bars }

        it { expect { subject.foosrs.to_a }.to raise_error(NameError) }
      end

      context 'Origin does not exist' do
        before(:each) { Bar.has_many :out, :foos, origin: :barsy }

        it { expect { subject.foos.to_a }.to raise_error(ArgumentError) }
      end

      context 'Direction is the same' do
        before(:each) { Bar.has_many :in, :foos, origin: :bars }

        it { expect { subject.foos.to_a }.to raise_error(ArgumentError) }
      end

    end
  end

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


    it 'evaluates `all` lazily' do
      result = Teacher.all
      expect(result).to be_a(Neo4j::ActiveNode::Query::QueryProxy)
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
          expect(samuels.lessons_teaching.to_a).to include(ss101, ss102)
          expect(samuels.lessons_teaching.count).to eq 2

          expect(samuels.lessons.to_a).to include(ss101, ss102, math101)
          expect(samuels.lessons.to_a.count).to eq 3
        end
      end
    end

    context 'bobby has teacher preferences' do
      before(:each) do
        bobby.favorite_teachers << samuels
        bobby.hated_teachers << othmar
      end

      it 'differentiates associations on the same model for the same class' do
        bobby.favorite_teachers.to_a.should == [samuels]
        bobby.hated_teachers.to_a.should == [othmar]
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
      end

      it 'allows filtering on associations' do
        samuels.lessons_teaching.where(level: 101).to_a.should == [ss101]
      end

      it 'allows class methods on associations' do
        samuels.lessons_teaching.level_number(101).to_a.should == [ss101]

        samuels.lessons_teaching.max_level.should == 103
        samuels.lessons_teaching.where(subject: 'Social Studies').max_level.should == 101
      end

      it 'allows chaining of scopes and then class methods' do
        samuels.lessons_teaching.level_number(101).max_level.should == 101
        samuels.lessons_teaching.level_number(103).max_level.should == 103
      end

      context 'samuels also teaching math 201' do
        before(:each) do
          samuels.lessons_teaching << math101
        end

        it 'allows chaining of class methods and then scopes' do
          samuels.lessons_teaching.ordered_by_subject.level_number(101).to_a.should == [math101, ss101]
        end
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

        describe 'on classes' do
          before(:each) do
            danny.lessons << math101
            rel = danny.lessons(:l, :r).pluck(:r).first
            rel[:grade] = 65

            bobby.lessons << math101
            rel = bobby.lessons(:l, :r).pluck(:r).first
            rel[:grade] = 71

            math101.teachers << othmar
            rel = math101.teachers(:t, :r).pluck(:r).first
            rel[:since] = 2001

            sandra.lessons << ss101
          end

          context 'students, age 15, who are taking level 101 lessons' do
            it { Student.as(:student).where(age: 15).lessons(:lesson).where(level: 101).pluck(:student).should == [danny] }
            it { Student.where(age: 15).lessons(:lesson).where(level: '101').pluck(:lesson).should_not == [[othmar]] }
            it do
              Student.as(:student).where(age: 15).lessons(:lesson).where(level: 101).pluck(:student).should ==
              Student.as(:student).node_where(age: 15).lessons(:lesson).node_where(level: 101).pluck(:student)
            end
          end

          context 'Students enrolled in math 101 with grade 65' do
            # with automatic identifier
            it { Student.as(:student).lessons.rel_where(grade: 65).pluck(:student).should == [danny] }

            # with manual identifier
            it { Student.as(:student).lessons(:l, :r).rel_where(grade: 65).pluck(:student).should == [danny] }

            # with multiple instances of rel_where
            it { Student.as(:student).lessons(:l).rel_where(grade: 65).teachers(:t, :t_r).rel_where(since: 2001).pluck(:t).should == [othmar] }
          end

          context 'with has_one' do
            before do
              math101.teachers_pet = bobby
              ss101.teachers_pet = sandra
              bobby.lessons << geo103
              bobby.hated_teachers << othmar
              sandra.hated_teachers << samuels
            end

            context 'on instances' do
              it { math101.teachers_pet(:l).lessons.where(level: 103).should == [geo103] }
            end

            context 'on class' do
              # Lessons of level 101 that have a teachers pet, age 16, whose hated teachers include Ms Othmar... Who hates Mrs Othmar!?
              it { Lesson.where(level: 101).teachers_pet(:s).where(age: 16).hated_teachers.where(name: 'Ms. Othmar').pluck(:s).should == [bobby] }
            end
          end
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
        samuels.interests.create(monster_trucks, intensity: 1)
        othmar.interests.create(monster_trucks, intensity: 11)
      end

      # Should get both
      it { monster_trucks.interested.count.should == 2 }
      it { monster_trucks.interested.to_a.should include(samuels, othmar) }

      # Variable assignment and filtering on a relationship
      it { monster_trucks.interested(:person, :r).where('r.intensity < 5').pluck(:person).should == [samuels] }

      it 'considers symbols as node fields for order' do
        monster_trucks.interested(:person).order(:name).pluck(:person).should == [samuels, othmar]
        monster_trucks.interested(:person, :r).order('r.intensity DESC').pluck(:person).should == [othmar, samuels]
      end
    end
  end

  describe 'batch finding' do
    let!(:ss101) { Lesson.create(subject: 'Social Studies', level: 101) }
    let!(:ss102) { Lesson.create(subject: 'Social Studies', level: 102) }
    let!(:math101) { Lesson.create(subject: 'Math', level: 101) }
    let!(:math201) { Lesson.create(subject: 'Math', level: 201) }
    let!(:geo103) { Lesson.create(subject: 'Geography', level: 103) }

    describe 'find_in_batches' do
      {
        1 => 5,
        2 => 3,
        3 => 2,
        4 => 2,
        5 => 1,
        6 => 1
      }.each do |batch_size, expected_yields|
        context "batch size of #{batch_size}" do
          it "yields #{expected_yields} times" do
            expect do |block|
              Lesson.find_in_batches(batch_size: batch_size, &block)
            end.to yield_control.exactly(expected_yields).times
          end
        end
      end
    end

    describe 'find_each' do
      {
        1 => 5,
        2 => 5,
        3 => 5,
        4 => 5,
        5 => 5,
        6 => 5
      }.each do |batch_size, expected_yields|
        context "batch size of #{batch_size}" do
          it "yields #{expected_yields} times" do
            expect do |block|
              Lesson.find_each(batch_size: batch_size, &block)
            end.to yield_control.exactly(expected_yields).times
          end
        end
      end
    end
  end
end
