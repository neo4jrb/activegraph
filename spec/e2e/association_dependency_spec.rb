require 'spec_helper'

describe 'association dependent delete/destroy' do
  module DependentSpec
    CALL_COUNT = { called: 0 }

    class Student
      include Neo4j::ActiveNode
      property :name
      property :call_count, type: Integer

      has_many :out, :lessons, model_class: 'DependentSpec::Lesson', type: 'ENROLLED_IN'
    end

    class Lesson
      include Neo4j::ActiveNode
      after_destroy lambda { DependentSpec::CALL_COUNT[:called] += 1 }
      property :subject
    end

    class << self
      def setup_callback(dependent_type)
        DependentSpec::Student.has_many :out, :lessons,  model_class: 'DependentSpec::Lesson', type: 'ENROLLED_IN', dependent: dependent_type
      end
    end
  end

  before do
    DependentSpec::CALL_COUNT[:called] = 0
    @billy = DependentSpec::Student.create(name: 'Billy')
    @jasmine = DependentSpec::Student.create(name: 'Jasmine')
    @math = DependentSpec::Lesson.create(subject: 'Math')
    @science = DependentSpec::Lesson.create(subject: 'Science')
    @billy.lessons << @math
    @billy.lessons << @science
    @jasmine.lessons << @science
  end

  describe 'dependent: :delete' do
    before do
      DependentSpec::Student.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:delete)
      @billy.reload
    end

    it 'deletes all association records from within Cypher' do
      DependentSpec::Student.before_destroy.clear
      [@math, @science].each { |l| expect(l).to be_persisted }
      @billy.destroy
      [@math, @science].each { |l| expect(l).not_to be_persisted }
      expect(DependentSpec::CALL_COUNT[:called]).to eq 0
    end
  end


  describe 'dependent: :delete_orphans' do

    before do
      DependentSpec::Student.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:delete_orphans)
      @billy.reload
    end

    require 'pry'
    it 'deletes all associated records that do not have other relationships of the same type from Cypher' do
      [@math, @science].each { |l| expect(l).to be_persisted }
      @billy.destroy
      expect(@math).not_to be_persisted
      expect(@science).to be_persisted
      expect(DependentSpec::CALL_COUNT[:called]).to eq 0
    end
  end

  describe 'dependent: :destroy' do
    before do
      DependentSpec::Student.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:destroy)
      @billy.reload
    end

    it 'destroys all associated records from Ruby' do
      DependentSpec::Student.before_destroy.clear
      [@math, @science].each { |l| expect(l).to be_persisted }
      @billy.destroy
      [@math, @science].each { |l| expect(l).not_to be_persisted }
      expect(DependentSpec::CALL_COUNT[:called]).to eq 2
    end
  end

  describe 'dependent :destroy_orphans' do
    before do
      DependentSpec::Student.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:destroy_orphans)
      @billy.reload
    end

    it 'destroys all associated records that do not have other relationships of the same type from Ruby' do
      [@math, @science].each { |l| expect(l).to be_persisted }
      @billy.destroy
      expect(@math).not_to be_persisted
      expect(@science).to be_persisted
      expect(DependentSpec::CALL_COUNT[:called]).to eq 1
    end
  end
end