require 'spec_helper'

def save_and_expect_rel!
  proc do
    chris.save
    reloaded_chris = Student.find_by(chris.props)
    expect(reloaded_chris.lessons.include?(math)).to be_truthy
  end
end

describe 'association creation' do
  before do
    stub_const('Student', Class.new do
      include Neo4j::ActiveNode
      property :name
      has_many :out, :lessons, type: 'ENROLLED_IN'
      has_one :out, :favorite_class, type: 'FAVORITE_CLASS', model_class: 'Lesson'
    end)

    stub_const('Lesson', Class.new do
      include Neo4j::ActiveNode
      property :subject
      validates_presence_of :subject
      has_many :in, :students, origin: :lesson
    end)
  end

  before { [Student, Lesson].each(&:delete_all) }

  describe 'has_one' do
    context 'with persisted nodes' do
      let(:chris) { Student.create(name: 'Chris') }
      let(:math)  { Lesson.create(subject: 'Math') }

      it 'creates the relationship' do
        expect { chris.favorite_class = math }.to change { chris.favorite_class }
      end
    end

    context 'between two unpersisted nodes' do
      let!(:chris) { Student.new(name: 'Chris') }
      let!(:math)  { Lesson.new(subject: 'Math') }

      it 'does not raise an error' do
        expect { chris.favorite_class = math }.not_to raise_error
      end

      it 'is aware that there are pending associations' do
        expect { chris.favorite_class = math }.to change { chris.pending_associations? }
      end

      context 'upon save...' do
        before do
          chris.favorite_class = math
        end

        it 'saves both nodes and creates the relationship' do
          expect(math).to receive(:save).and_call_original
          expect { chris.save }.to change { chris.favorite_class }
        end
      end
    end
  end

  describe 'has_many' do
    context 'with persisted nodes' do
      let(:chris) { Student.create(name: 'Chris') }
      let(:math)  { Lesson.create(subject: 'Math') }

      it 'creates a relationship' do
        expect { chris.lessons << math }.to change { chris.lessons.count }
      end
    end

    context 'between two unpersisted nodes' do
      let(:chris) { Student.new(name: 'Chris') }
      let(:math)  { Lesson.new(subject: 'Math') }

      it 'does not raise an error' do
        expect { chris.lessons << math }.not_to raise_error
      end

      it 'does not create new nodes' do
        expect { chris.lessons << math }.not_to change { Student.count == 0 && Lesson.count == 0 }
      end

      it 'is aware that there are cascading relationships' do
        expect { chris.lessons << math }.to change { chris.pending_associations? }
      end

      context 'upon save...' do
        before { chris.lessons << math }

        it 'saves both nodes' do
          expect { chris.save }.to change { math.exist? }
        end

        it 'creates the relationship' do
          save_and_expect_rel!.call
        end

        context 'with a save failure' do
          let(:unnamed_lesson) { Lesson.new }
          before do
            expect(unnamed_lesson).not_to be_valid
            chris.lessons << unnamed_lesson
          end

          it 'rolls back the entire transaction' do
            expect { chris.save }.to raise_error
            expect(chris).not_to exist
          end
        end
      end
    end

    context 'between unpersisted and persisted, unchanged nodes' do
      let(:chris) { Student.new(name: 'Chris') }
      let(:math) { Lesson.create(subject: 'math') }

      it 'does not save the unpersisted node' do
        expect(chris).not_to receive(:save)
        chris.lessons << math
      end

      context 'upon save...' do
        it 'only saves the unpersisted node' do
          expect(math).not_to receive(:save)
          chris.lessons << math
          chris.save
        end

        it 'creates the relationship' do
          chris.lessons << math
          save_and_expect_rel!.call
        end
      end
    end

    context 'between persisted and unpersisted' do
      let!(:chris) { Student.create(name: 'Chris') }
      let!(:math) { Lesson.new(subject: 'math') }

      it 'saves the unpersisted node and immediately creates the rel' do
        expect { chris.lessons << math }.to change { chris.lessons.include?(math) }
      end
    end
  end
end
