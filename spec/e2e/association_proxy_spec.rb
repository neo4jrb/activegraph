require 'spec_helper'

describe 'Association Proxy' do
  before(:each) do
    clear_model_memory_caches

    stub_active_node_class('Student') do
      property :name
      has_many :out, :lessons, type: :has_student, model_class: 'Lesson'
      has_many :in, :exams, model_class: 'Exam', origin: :students
      has_one :out, :favorite_lesson, model_class: 'Lesson'
    end

    stub_active_node_class('Lesson') do
      property :subject
      property :level, type: Integer
      has_many :in, :students, model_class: Student, origin: :lessons
      has_many :out, :exams_given, model_class: 'Exam'
    end

    stub_active_node_class('Exam') do
      property :name
      has_many :in, :lessons, model_class: 'Lesson', origin: :exams_given
      has_many :out, :students, type: :has_student, model_class: Student
    end
  end

  let(:billy)     { Student.create(name: 'Billy') }
  let(:math)      { Lesson.create(subject: 'math', level: 101) }
  let(:science)   { Lesson.create(subject: 'science', level: 102) }
  let(:math_exam) { Exam.create(name: 'Math Exam') }
  let(:science_exam) { Exam.create(name: 'Science Exam') }

  before do
    [math, science].each { |lesson| billy.lessons << lesson }
    [math_exam, science_exam].each { |exam| billy.exams << exam }
    math.exams_given << math_exam
    science.exams_given << science_exam
    billy.favorite_lesson = math
  end

  it 'Should only make one query per association' do
    expect_queries(2) do
      billy.lessons.each do |lesson|
        lesson.exams_given.each do |exam|
          # nil
        end
      end
    end
  end
end