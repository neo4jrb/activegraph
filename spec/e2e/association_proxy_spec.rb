describe 'Association Proxy' do
  before do
    clear_model_memory_caches
    delete_db

    stub_active_node_class('Student') do
      property :name
      has_many :out, :lessons, type: :has_student, model_class: :Lesson
      has_many :in, :exams, model_class: :Exam, origin: :students
      has_one :out, :favorite_lesson, type: nil, model_class: :Lesson
    end

    stub_active_node_class('Lesson') do
      property :subject
      property :level, type: Integer
      has_many :in, :students, model_class: :Student, origin: :lessons
      has_many :out, :exams_given, type: nil, model_class: :Exam
    end

    stub_active_node_class('Exam') do
      property :name
      has_many :in, :lessons, model_class: :Lesson, origin: :exams_given
      has_many :out, :students, type: :has_student, model_class: :Student
    end
  end

  let(:billy)     { Student.create(name: 'Billy') }
  let(:math)      { Lesson.create(subject: 'math', level: 101) }
  let(:science)   { Lesson.create(subject: 'science', level: 102) }
  let(:math_exam) { Exam.create(name: 'Math Exam') }
  let(:science_exam) { Exam.create(name: 'Science Exam') }
  let(:science_exam2) { Exam.create(name: 'Science Exam 2') }

  before do
    [math, science].each { |lesson| billy.lessons << lesson }
    [math_exam, science_exam].each { |exam| billy.exams << exam }
    math.exams_given << math_exam
    science.exams_given << science_exam
    science.exams_given << science_exam2
    billy.favorite_lesson = math
  end

  it 'Should only make one query per association' do
    expect(billy.lessons.exams_given.to_a).to match_array([math_exam, science_exam, science_exam2])

    expect_queries(3) do
      grouped_lessons = billy.lessons.group_by(&:subject)

      expect(billy.lessons.to_a).to match_array([math, science])
      expect(grouped_lessons['math'][0].exams_given.to_a).to eq([math_exam])
      expect(grouped_lessons['science'][0].exams_given.to_a).to match_array([science_exam, science_exam2])

      expect(grouped_lessons['math'][0].students.to_a).to eq([billy])
      expect(grouped_lessons['science'][0].students.to_a).to eq([billy])
    end
  end

  it 'Should only make one query association from a model query' do
    expect_queries(3) do
      grouped_exams = Exam.all.group_by(&:name)

      expect(grouped_exams['Science Exam'][0].students.to_a).to eq([billy])
      expect(grouped_exams['Science Exam'][0].lessons.to_a).to eq([science])

      expect(grouped_exams['Math Exam'][0].students.to_a).to eq([billy])
      expect(grouped_exams['Math Exam'][0].lessons.to_a).to eq([math])
    end
  end

  it 'Should allow for loading of associations with one query' do
    expect_queries(1) do
      grouped_lessons = billy.lessons.with_associations(:exams_given, :students).group_by(&:subject)

      expect(grouped_lessons['math'][0].students).to eq([billy])
      expect(grouped_lessons['math'][0].exams_given).to eq([math_exam])

      expect(grouped_lessons['science'][0].students).to eq([billy])
      expect(grouped_lessons['science'][0].exams_given).to match_array([science_exam, science_exam2])
    end
  end

  it 'Should allow for loading of `has_one` association' do
    expect_queries(1) do
      grouped_students = science.students.with_associations(:favorite_lesson).group_by(&:name)

      expect(grouped_students['Billy'][0].favorite_lesson).to eq(math)

      expect(grouped_students.size).to eq(1)
      expect(grouped_students['Billy'].size).to eq(1)
    end
  end

  it 'Queries limited times in depth two loops with with_associations' do
    Student.create.lessons << science
    Student.create.lessons << science
    expect_queries(4) do
      science.students.with_associations(:lessons).each do |student|
        student.lessons.with_associations(:exams_given).each do |lesson|
          lesson.exams_given.to_a
        end
      end
    end
  end

  it 'Queries limited times in depth two loops' do
    Student.create.lessons << science
    Student.create.lessons << science
    expect_queries(5) do
      science.students.each do |student|
        student.lessons.each do |lesson|
          lesson.exams_given.to_a
        end
      end
    end
  end

  it 'does not make extra queries when using .create' do
    lesson = Lesson.create
    expect_queries(2) do
      science.students.each do |student|
        student.lessons.create(lesson)
      end
    end
  end

  describe 'issue reported by @andrewhavens in #881' do
    it 'does not break' do
      l1 = Lesson.create!.tap { |l| l.exams_given = [Exam.create!] }
      l2 = Lesson.create!.tap { |l| l.exams_given = [Exam.create!, Exam.create!] }
      student = Student.create!.tap { |s| s.lessons = [l1, l2] }
      totals = {l1.id => l1.exams_given.count, l2.id => l2.exams_given.count}

      student.lessons.each do |l|
        expect(totals[l.id]).to eq l.exams_given.count
      end
    end
  end

  describe 'target' do
    context 'when none found' do
      it 'raises an error' do
        expect { billy.lessons.foo }.to raise_error NoMethodError
      end
    end
  end

  context 'when requiring "active_support/core_ext/enumerable"' do
    require 'active_support/core_ext/enumerable'

    it 'uses the correct `pluck` method' do
      expect(billy.lessons(:l).pluck(:l)).not_to include(nil)
      expect(billy.lessons(:l).method(:pluck).source_location.first).not_to include('active_support')
    end
  end
end
