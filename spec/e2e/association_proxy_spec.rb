describe 'Association Proxy' do
  before do
    clear_model_memory_caches
    delete_db

    stub_active_node_class('Student') do
      property :name
      has_many :out, :lessons, rel_class: :LessonEnrollment
      has_many :in, :exams, model_class: :Exam, origin: :students
      has_one :out, :favorite_lesson, type: nil, model_class: :Lesson
    end

    stub_active_rel_class('LessonEnrollment') do
      from_class :Student
      to_class   :Lesson
      type :has_studet

      property :grade
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

  it 'allows associations to respond to to_ary' do
    expect(billy.lessons).to respond_to(:to_ary)
    expect(billy.lessons.exams_given).to respond_to(:to_ary)
  end

  it 'Should only make one query per association' do
    expect(billy.lessons.exams_given).to match_array([math_exam, science_exam, science_exam2])

    expect_queries(3) do
      grouped_lessons = billy.lessons.group_by(&:subject)

      expect(billy.lessons).to match_array([math, science])
      expect(grouped_lessons['math'][0].exams_given).to eq([math_exam])
      expect(grouped_lessons['science'][0].exams_given).to match_array([science_exam, science_exam2])

      expect(grouped_lessons['math'][0].students).to eq([billy])
      expect(grouped_lessons['science'][0].students).to eq([billy])
    end
  end

  it 'Should only make one query association from a model query' do
    expect_queries(3) do
      grouped_exams = Exam.all.group_by(&:name)

      expect(grouped_exams['Science Exam'][0].students).to eq([billy])
      expect(grouped_exams['Science Exam'][0].lessons).to eq([science])

      expect(grouped_exams['Math Exam'][0].students).to eq([billy])
      expect(grouped_exams['Math Exam'][0].lessons).to eq([math])
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

  it 'Should allow for loading of associations with one query on multiple to_a calls' do
    expect_queries(1) do
      query = billy.lessons.with_associations(:exams_given, :students)
      query.to_a
      query.to_a
    end
  end

  it 'Should allow for loading of associations with one query when method chain ends with first' do
    expect_queries(1) do
      billy.lessons.with_associations(:exams_given).first.exams_given.to_a
    end
  end

  it 'Should allow for loading of associations with one query when method chain ends with branch' do
    expect_queries(1) do
      billy.as(:b).with_associations(:lessons).branch { lessons }.first.lessons.to_a
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

  it 'Queries limited times in depth two loops with deep with_associations' do
    Student.create.lessons << science
    Student.create.lessons << science
    expect_queries(1) do
      science.students.with_associations(lessons: :exams_given).each do |student|
        student.lessons.each do |lesson|
          lesson.exams_given.to_a
        end
      end
    end
  end

  it 'Queries limited times in depth two loops with deep with_associations iterating over relationships' do
    Student.create.lessons << science
    Student.create.lessons << science
    expect_queries(1) do
      science.students.with_associations(lessons: :exams_given).each do |student|
        student.lessons.rels.each do |lesson_rel|
          lesson_rel.end_node.exams_given.to_a
        end
      end
    end
  end

  it 'Queries limited times in depth two loops with deep with_associations iterating over relationships with each_rel' do
    Student.create.lessons << science
    Student.create.lessons << science
    expect_queries(1) do
      science.students.with_associations(lessons: :exams_given).each do |student|
        student.lessons.each_rel do |lesson_rel|
          lesson_rel.end_node.exams_given.to_a
        end
      end
    end
  end

  it 'Queries only one time when there are some empty associations' do
    Student.create.lessons << science
    Student.create.lessons += [science, Lesson.create]
    expect_queries(1) do
      science.students.with_associations(lessons: :exams_given).flat_map(&:lessons).flat_map(&:exams_given)
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

  describe 'support relationship type as label' do
    before do
      stub_active_node_class('Roster') do
        has_many :out, :students, type: :student
      end
    end

    it 'Queries only 1 time' do
      Roster.create(students: [billy])
      expect_queries(1) do
        Roster.all.with_associations(:students).each do |roster|
          roster.students.to_a
        end
      end
    end
  end

  describe 'ordering' do
    it 'supports before with_association' do
      expect(Lesson.order(:subject).with_associations(:students).map(&:subject)).to eq(%w(math science))
      expect(Lesson.order(subject: :desc).with_associations(:students).map(&:subject)).to eq(%w(science math))
    end

    it 'supports after with_association' do
      expect(Lesson.all.with_associations(:students).order(:subject).map(&:subject)).to eq(%w(math science))
      expect(Lesson.all.with_associations(:students).order(subject: :desc).map(&:subject)).to eq(%w(science math))
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

  describe '#inspect' do
    context 'when inspecting an association proxy' do
      let(:association_proxy) { billy.lessons }
      let(:inspected_elements) { association_proxy.inspect }

      it 'returns the list of resulting elements' do
        expect(inspected_elements).to include('#<AssociationProxy Student#lessons')
        expect(inspected_elements).to include(association_proxy.to_a.inspect)
      end
    end
  end
end
