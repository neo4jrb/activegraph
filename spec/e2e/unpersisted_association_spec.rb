def save_and_expect_rel!
  proc do
    chris.save
    reloaded_chris = Student.find_by(chris.props)
    expect(reloaded_chris.lessons.include?(math)).to be_truthy
  end
end

describe 'association creation' do
  before do
    clear_model_memory_caches

    stub_active_node_class 'Student' do
      property :name
      has_many :out, :lessons, type: 'ENROLLED_IN'
      has_one :out, :favorite_class, type: 'FAVORITE_CLASS', model_class: 'Lesson'
    end

    stub_active_node_class 'Lesson' do
      property :subject
      validates_presence_of :subject
      has_many :in, :students, origin: :lesson
    end
  end

  before { [Student, Lesson].each(&:delete_all) }

  describe 'has_one' do
    context 'with persisted nodes' do
      let(:chris) { Student.create(name: 'Chris') }
      let(:math)  { Lesson.create(subject: 'Math') }

      it 'creates the relationship' do
        expect { chris.favorite_class = math }.to change { chris.favorite_class }
      end

      it 'creates the relationship by id' do
        expect { chris.favorite_class_id = math.id }.to change { chris.favorite_class }
      end
    end

    context 'assigning via #new method arguments' do
      let!(:math)  { Lesson.new(subject: 'Math') }
      let!(:chris) do
        Student.new(name: 'Chris', favorite_class: math)
      end

      it 'returns the node' do
        expect(chris.favorite_class).to eq(math)
      end

      context 'upon save...' do
        before { chris.save }

        it 'returns the node' do
          expect(chris.favorite_class).to eq(math)
          expect(chris.query_as(:c).match('(c)-[rel:FAVORITE_CLASS]-()').count(:rel)).to eq(1)
        end
      end
    end

    context 'between two unpersisted nodes' do
      let!(:chris) { Student.new(name: 'Chris') }
      let!(:math)  { Lesson.new(subject: 'Math') }

      it 'does not raise an error' do
        expect { chris.favorite_class = math }.not_to raise_error
      end

      it 'is aware that there are pending associations' do
        expect { chris.favorite_class = math }.to change { chris.pending_deferred_creations? }
      end

      context 'upon save...' do
        before do
          chris.favorite_class = math
        end

        it 'saves both nodes and creates the relationship' do
          expect(math).to receive(:save).and_call_original
          expect { chris.save }.to change { chris.favorite_class.object_id }
        end

        it 'returns the node' do
          expect(chris.favorite_class).to eq(math)
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

    context 'assigning via #new method arguments' do
      let!(:math)  { Lesson.new(subject: 'Math') }
      let!(:chris) { Student.new(name: 'Chris', lessons: [math]) }

      context 'upon save...' do
        it 'returns the node' do
          expect(chris.lessons).to eq([math])
        end
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
        expect { chris.lessons << math }.to change { chris.pending_deferred_creations? }
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
            expect { chris.save }.to raise_error(/Unable to defer node persistence, could not save/)
            expect(chris).not_to exist
          end
        end
      end
    end

    context 'between many unpersisted nodes' do
      let(:chris) { Student.new(name: 'Chris') }
      let(:math)  { Lesson.new(subject: 'Math') }
      let(:science) { Lesson.new(subject: 'Science') }
      let(:lessons) { [math, science] }

      context 'associated as an array' do
        it 'delays the call to :save' do
          expect(science).not_to receive(:save)
          expect { chris.lessons += lessons }.not_to raise_error
        end

        it 'calls save on each element' do
          expect(math).to receive(:save).and_call_original
          expect(science).to receive(:save).and_call_original
          chris.lessons += lessons
          chris.save
        end
      end

      context 'associated individually' do
        it 'calls save on each node' do
          expect(math).to receive(:save).and_call_original
          expect(science).to receive(:save).and_call_original
          chris.lessons << math
          chris.lessons << science
          chris.save
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
        expect { chris.lessons << math }.to change { chris.lessons.where(subject: 'math').empty? }
      end
    end

    context 'between unpersisted and ids' do
      let(:chris) { Student.new(name: 'Chris') }
      let!(:math) { Lesson.create(subject: 'math') }

      it 'does not raise error, creates rel on save' do
        expect_any_instance_of(Neo4j::Core::Query).not_to receive(:delete)
        expect { chris.lesson_ids = [math.id] }.not_to raise_error
        expect { chris.save }.to change { chris.lessons.count }
      end
    end
  end


  describe '... on creation' do
    context 'with math lesson' do
      let(:math) { Lesson.create(subject: 'math') }
      let(:science) { Lesson.create(subject: 'Science') }

      describe 'has_one' do
        it 'creates the relationship by the association name' do
          chris = Student.create(name: 'Chris', favorite_class: math)
          expect(chris.errors).to be_empty

          lessons = chris.query_as(:c).match('(c)-[:FAVORITE_CLASS]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end

        it 'creates the relationship by assigning to an unpersisted node' do
          chris = Student.new(name: 'Chris')
          chris.favorite_class = math

          expect(chris.favorite_class).to eq(math)
          expect(chris.favorite_class_id).to eq(math.id)

          expect(chris.errors).to be_empty

          chris.save

          lessons = chris.query_as(:c).match('(c)-[:FAVORITE_CLASS]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end

        it 'does not double add when assigning has_many associations twice' do
          chris = Student.new(name: 'Chris')
          chris.favorite_class = math
          chris.favorite_class = math

          expect(chris.favorite_class).to eq(math)
          expect(chris.favorite_class_id).to eq(math.id)

          expect(chris.errors).to be_empty

          chris.save

          lessons = chris.query_as(:c).match('(c)-[:FAVORITE_CLASS]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end

        it 'creates the relationship by the association_id' do
          chris = Student.create(name: 'Chris', favorite_class_id: math.id)
          expect(chris.errors).to be_empty

          lessons = chris.query_as(:c).match('(c)-[:FAVORITE_CLASS]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end

        it 'creates the relationship by assigning association_id to an unpersisted node' do
          chris = Student.new(name: 'Chris')
          chris.favorite_class_id = math.id

          expect(chris.favorite_class).to eq(math)
          expect(chris.favorite_class_id).to eq(math.id)

          expect(chris.errors).to be_empty

          chris.save

          lessons = chris.query_as(:c).match('(c)-[:FAVORITE_CLASS]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end
      end

      describe 'has_many' do
        it 'creates the relationship by the association name' do
          chris = Student.create(name: 'Chris', lessons: [math])
          expect(chris.errors).to be_empty

          lessons = chris.query_as(:c).match('(c)-[:ENROLLED_IN]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end

        it 'creates the relationship by assigning to an unpersisted node' do
          chris = Student.new(name: 'Chris')
          chris.lessons = [math]

          expect(chris.lessons).to eq([math])
          expect(chris.lesson_ids).to eq([math.id])

          expect(chris.errors).to be_empty

          chris.save

          lessons = chris.query_as(:c).match('(c)-[:ENROLLED_IN]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end

        it 'does not double add when assigning has_many associations twice' do
          chris = Student.new(name: 'Chris')
          chris.lessons = [math]
          chris.lessons = [science]

          expect(chris.lessons).to eq([science])
          expect(chris.lesson_ids).to eq([science.id])

          expect(chris.errors).to be_empty

          chris.save

          lessons = chris.query_as(:c).match('(c)-[:ENROLLED_IN]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([science.id])
        end

        it 'creates the relationship by the association_id' do
          chris = Student.create(name: 'Chris', lesson_ids: [math.id])
          expect(chris.errors).to be_empty

          lessons = chris.query_as(:c).match('(c)-[:ENROLLED_IN]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end

        it 'creates the relationship by assigning association_id to an unpersisted node' do
          chris = Student.new(name: 'Chris')
          chris.lesson_ids = [math.id]

          expect(chris.lessons).to eq([math])
          expect(chris.lesson_ids).to eq([math.id])

          expect(chris.errors).to be_empty

          chris.save

          lessons = chris.query_as(:c).match('(c)-[:ENROLLED_IN]->(l:Lesson)').pluck('l.uuid')
          expect(lessons).to match_array([math.id])
        end
      end
    end
  end
end
