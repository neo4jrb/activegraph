require 'spec_helper'

describe 'Association Cache' do
  module CachingSpec
    class Lesson; end
    class Exam; end

    class Student
      include Neo4j::ActiveNode
      property :name
      has_many :out, :lessons, model_class: Lesson
      has_many :in, :exams, model_class: Exam, origin: :students
      has_one  :out, :favorite_lesson, model_class: Lesson
    end

    class Lesson
      include Neo4j::ActiveNode
      property :subject
      property :level, type: Integer
      has_many :in, :students, model_class: Student, origin: :lessons
      has_many :out, :exams_given, model_class: Exam
    end

    class Exam
      include Neo4j::ActiveNode
      property :name
      has_many :in, :lessons, model_class: Lesson, origin: :exams_given
      has_many :out, :students, model_class: Student
    end
  end

  let(:billy)     { CachingSpec::Student.create(name: 'Billy') }
  let(:math)      { CachingSpec::Lesson.create(subject: 'math', level: 101 ) }
  let(:science)   { CachingSpec::Lesson.create(subject: 'science', level: 102) }
  let(:math_exam) { CachingSpec::Exam.create(name: 'Math Exam') }
  let(:science_exam) { CachingSpec::Exam.create(name: 'Science Exam') }
  let(:cache)     { billy.association_cache }

  before do
    [math, science].each { |lesson| billy.lessons << lesson }
    [math_exam, science_exam].each { |exam| billy.exams << exam }
    math.exams_given << math_exam
    science.exams_given << science_exam
    billy.favorite_lesson = math
  end

  context 'with no results' do
    it 'does not change when query has no results' do
      result = billy.exams.where(level: 9000).to_a
      expect(result).to be_empty
      expect(cache).to be_empty
    end
  end

  context 'on a class' do
    describe 'association_cache method' do
      it 'raises an error because it is only for instances' do
        expect{CachingSpec::Student.association_cache}.to raise_error
      end
    end

    it 'does not have @association_cache variable' do
      expect(CachingSpec::Student.instance_variable_get(:@association_cache)).to be_nil
    end
  end

  context 'with a matching query' do
    describe 'using has_one' do
      before { billy.favorite_lesson }

      it 'populates the association cache' do
        expect(cache).not_to be_empty
      end

      it 'draws from cache, not server, when results are found' do
        billy.reload
        query_proxy = Neo4j::ActiveNode::Query::QueryProxy
        expect(billy).to receive(:association_instance_get).and_return nil
        billy.favorite_lesson

        expect(billy).to receive(:association_instance_get).and_return math
        billy.favorite_lesson
      end
    end

    describe 'using has_many' do
      before { billy.lessons.to_a }

      it 'populates the association cache' do
        expect(cache).not_to be_empty
      end

      it 'creates a hash based on the cypher that generated the query' do
        hash_string = billy.cypher_hash(billy.lessons.to_cypher_with_params)
        expect(cache).to have_key(:lessons)
        expect(cache[:lessons]).to have_key(hash_string)
        expect(cache[:lessons][hash_string]).to eq billy.lessons.to_a
      end

      context 'with additional queries' do
        let!(:original_query) { billy.lessons }
        let!(:original_hash_string) { billy.cypher_hash(original_query.to_cypher_with_params) }
        let!(:level_query)      { billy.lessons.where(level: 102) }
        let!(:new_hash_string)  { billy.cypher_hash(level_query.to_cypher_with_params) }
        let!(:new_query_result) { level_query.to_a }

        it 'adds an additional key to the hash of the association when the query changes' do
          expect(new_query_result).to eq [science]
          expect(cache[:lessons]).to have_key(original_hash_string)
          expect(cache[:lessons]).to have_key(new_hash_string)
          expect(cache[:lessons][new_hash_string]).to eq new_query_result
        end

        it 'returns the exected result' do
          expect(original_query.count).to eq 2
          expect(original_query.to_a).to include(math, science)
          expect(new_query_result).to eq [science]
        end

        it 'leaves existing cache results intact' do
          expect(cache[:lessons]).to have_key(original_hash_string)
          expect(cache[:lessons]).to have_key(new_hash_string)
        end

        it 'does not communicate with the database if @association_cache already contains a key matching the hash' do
          query_proxy = billy.lessons
          expect(query_proxy).to receive(:pluck).exactly(1).times.and_return [math, science]
          query_proxy.to_a
          billy.reload
          query_proxy.to_a
        end
      end

      it 'clears when the node is saved' do
        billy.save
        expect(cache).to be_empty
      end

      it 'clears when reload is called' do
        billy.reload
        expect(cache).to be_empty
      end

      it 'does not cache chained results in the starting node cache' do
        starting_cache = billy.association_cache.dup
        billy.lessons.exams_given.to_a
        expect(starting_cache).to eq cache
      end

      it 'does not break the saving of related objects' do
        billy.lessons.each do |l|
          l.level = 201
          l.save
        end
        math.reload
        expect(math.level).to eq 201
      end

      describe 'returning with rel' do
        before { billy.reload }

        it 'differentiates between a query returning a node and node + rel' do
          cache_without_rel = billy.association_cache.dup
          billy.reload # clear association cache

          query_with_identifiers = billy.lessons(:node, :rel)
          query_with_identifiers.each_with_rel.to_a # add new entry to cache
          expected_key = billy.cypher_hash(query_with_identifiers.to_cypher_with_params([:node, :rel]))
          expect(cache[:lessons]).to have_key(expected_key)
          expect(cache_without_rel).not_to eq billy.association_cache
        end
      end

      describe 'association_instance_get_by_reflection' do
        it 'returns all results from the association_cache using an association name' do
          result = billy.association_instance_get_by_reflection(:lessons)
          query_hash = billy.cypher_hash(billy.lessons.to_cypher_with_params)
          expect(result).to have_key query_hash
          expect(result[query_hash].count).to eq 2
          expect(result[query_hash]).to include(math, science)
        end
      end

      context 'within a transaction' do
        it 'does not set results' do
          billy.reload
          tx = Neo4j::Transaction.new
            history = CachingSpec::Lesson.create(subject: 'history', level: 101 )
            billy.lessons << history
            billy.lessons.to_a # would typically cache results
          tx.close
          expect(cache).to be_empty
          expect(billy.lessons.include?(history)).to be_truthy
          billy.lessons.to_a
          expect(cache).not_to be_empty
        end
      end
    end
  end
end