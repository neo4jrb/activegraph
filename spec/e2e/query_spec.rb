require 'set'



describe 'Query API' do
  before(:each) do
    delete_db
    clear_model_memory_caches
  end


  before(:each) do
    stub_active_node_class('Interest') do
      property :name

      has_many :both, :interested, type: nil, model_class: false
    end

    stub_active_node_class('Lesson') do
      property :subject
      property :level

      has_one :out, :teachers_pet, model_class: 'Student', type: 'favorite_student'
      has_many :in, :unhappy_teachers, model_class: 'Teacher', origin: :dreaded_lesson
      has_many :in, :teachers, type: :teaching
      has_many :in, :students, rel_class: 'IsEnrolledFor'

      def self.max_level
        all.query_as(:lesson).pluck('max(lesson.level)').first
      end

      def self.ordered_by_subject
        all.order(:subject)
      end

      scope :level_number, ->(num) { where(level: num) }
    end

    stub_active_node_class('Student') do
      property :name
      property :age, type: Integer

      property :likely_to_succeed, type: Neo4j::Shared::Boolean, default: false

      has_many :out, :lessons, rel_class: 'IsEnrolledFor'

      has_many :out, :interests, type: nil

      has_many :both, :favorite_teachers, type: nil, model_class: 'Teacher'
      has_many :both, :hated_teachers, type: nil, model_class: 'Teacher'
      has_many :in,   :winning_lessons, model_class: 'Lesson', origin: :teachers_pet
    end

    stub_active_rel_class('IsEnrolledFor') do
      from_class :Student
      to_class :Lesson
      type 'is_enrolled_for'

      property :grade, type: Integer
    end

    stub_active_node_class('Teacher') do
      property :name
      property :age, type: Integer
      property :status, default: 'active'
      property :created_at
      property :updated_at

      has_many :both, :lessons, type: nil

      has_many :out, :lessons_teaching, type: nil, model_class: 'Lesson'
      has_many :out, :lessons_taught, type: nil, model_class: 'Lesson'

      has_many :out, :interests, type: nil
      has_one :out, :dreaded_lesson, model_class: 'Lesson', type: 'least_favorite_lesson'
    end
  end

  describe 'basic methods' do
    it 'allows for plucking of variables' do
      lesson = Lesson.create
      student = Student.create
      student.lessons << lesson

      expect(Student.as(:s).pluck(:s)).to eq([student])
      expect(Student.all.pluck(:uuid)).to eq([student.uuid])

      expect(lesson.students.pluck(:uuid)).to eq([student.uuid])
    end

    it 'responds to to_ary' do
      lesson = Lesson.create
      student = Student.create
      student.lessons << lesson

      expect(student.lessons.to_ary).to be_instance_of(Array)
      expect(student.lessons.to_ary).to eq(student.lessons.to_a)
    end
  end

  describe 'association validation' do
    before(:each) do
      %w(Foo Bar).each do |const|
        stub_active_node_class(const)
      end
    end

    context 'Foo has an association to Bar' do
      before(:each) do
        Foo.has_many :in, :bars, type: nil, model_class: :Bar
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

        it { expect { subject.foosrs.to_a }.to raise_error(ArgumentError, /Could not find class.*Foosr/) }
      end

      context 'Specified model does not exist' do
        before(:each) { Bar.has_many :out, :foosrs, model_class: 'Foosrs', origin: :bars }

        it { expect { subject.foosrs.to_a }.to raise_error(ArgumentError, /Could not find class.*Foosrs/) }
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
      expect(result.size).to eq(2)
      expect(result).to include(samuels)
      expect(result).to include(othmar)
    end

    describe 'filtering' do
      it 'allows filtering in where' do
        expect(Teacher.where(name: /.*Othmar.*/).to_a).to eq([othmar])
      end

      it 'allows NOT() filtering in where' do
        expect(Teacher.where_not(name: /.*Othmar.*/).to_a).to eq([samuels])
      end

      it 'allows filtering by String in where' do
        expect(Teacher.as(:teach).where('teach.name =~ ".*Othmar.*"').to_a).to eq([othmar])

        expect(Teacher.as(:teach).where('teach.name =~ ?', '.*Othmar.*').to_a).to eq([othmar])
      end

      it 'allows filtering by array' do
        expect(Student.as(:s).where('s.name IN ?', %w(Danny Sandra)).to_a).to contain_exactly(danny, sandra)
      end

      it 'allows filtering and parametarizing by String and Hash in where' do
        expect(Teacher.as(:teach).where('teach.name =~ {name}', name: '.*Othmar.*').to_a).to eq([othmar])
      end
    end

    describe 'merge methods' do
      before { Teacher.delete_all }

      describe '.merge' do
        let(:timestamps) { [1, 1, 2, 3].map(&DateTime.method(:new)) }
        let(:merge_attrs) { {name: 'Dr. Dre'} }
        let(:on_match_clause) { {} }
        let(:on_create_clause) { {} }
        let(:set_attrs) { {status: 'on create status'} }

        before { allow(DateTime).to receive(:now).and_return(*timestamps) }
        after { expect(Teacher.count).to eq 1 }

        # The ActiveNode stubbing is doing some odd things with the `name` method on the defined classes,
        # so please excuse this kludge.
        after(:all) do
          Object.send(:remove_const, :TeacherFoo)
          Object.send(:remove_const, :Substitute)
        end

        class TeacherFoo
          include Neo4j::ActiveNode
        end

        class Substitute < TeacherFoo
          include Neo4j::ActiveNode
        end

        subject { Teacher.merge(merge_attrs, on_match: on_match_clause, on_create: on_create_clause, set: set_attrs) }

        its(:name) { is_expected.to eq 'Dr. Dre' }

        context 'expected labels' do
          subject do
            super()
            Substitute.merge({})
          end

          its(:labels) { is_expected.to match_array [:TeacherFoo, :Substitute] }
        end

        let_context 'on_create', on_create_clause: {age: 49} do
          its(:age) { is_expected.to eq 49 }
          its(:status) { is_expected.to eq 'on create status' }

          it 'has the same created and updated' do
            expect(subject.created_at).to eq subject.updated_at
          end
        end


        let_context 'on_merge', on_match_clause: {age: 50}, on_create_clause: {age: 49}, set_attrs: {status: 'on match status'} do
          before { Teacher.merge(on_create_clause.merge(merge_attrs)) }

          its(:age) { is_expected.to eq 50 }
          its(:status) { is_expected.to eq 'on match status' }

          it 'updated_at' do
            expect(subject.updated_at).to be > subject.created_at
          end
        end

        describe 'string clauses' do
          let_context on_match_clause: 'n.age = 30 + 1', on_create_clause: 'n.age = 30 + 2' do
            its(:age) { is_expected.to eq 32 }
          end

          let_context on_match_clause: 'n.age = 30 + 1', on_create_clause: 'n.age = 30 + 2' do
            before { Teacher.create(merge_attrs) }
            its(:age) { is_expected.to eq 31 }
          end
        end

        context 'valid options' do
          before { Teacher.merge(merge_attrs) }

          subject { -> { Teacher.merge(merge_attrs, extra: 'thing') } }

          it { is_expected.to raise_error ArgumentError, 'Unknown key: :extra. Valid keys are: :on_create, :on_match, :set' }
        end
      end

      describe '.find_or_create' do
        it 'works like .merge with just matching attributes' do
          Teacher.find_or_create(name: 'Dr. Harold Samuels')
          expect(Teacher.count).to eq(1)
          expect(Teacher.first.name).to eq('Dr. Harold Samuels')
          Teacher.find_or_create(name: 'Dr. Harold Samuels')
          expect(Teacher.count).to eq(1)
        end

        it 'also sets properties on create' do
          Teacher.find_or_create({name: 'Dr. Harold Samuels'}, age: 34)

          expect(Teacher.count).to eq(1)

          samuels = Teacher.all.first
          expect(samuels.name).to eq('Dr. Harold Samuels')
          expect(samuels.age).to eq(34)
          expect(samuels.status).to eq('active')
          expect(samuels._persisted_obj.props[:status]).to eq 'active'
        end

        it 'overrides default properties on create' do
          Teacher.find_or_create({name: 'Dr. Harold Samuels'}, age: 34, status: 'inactive')

          expect(Teacher.count).to eq(1)

          samuels = Teacher.all.first
          expect(samuels.status).to eq('inactive')
        end

        it 'sets the id property method' do
          teacher = Teacher.find_or_create(name: 'Dr. Harold Samuels')
          expect(teacher.uuid).not_to be nil
        end

        context 'custom id property method' do
          before do
            stub_active_node_class('CustomTeacher') do
              id_property :custom_uuid, on: :custom_prop_method
              property :name

              def custom_prop_method
                "#{self.name.delete('.').delete(' ')}_#{SecureRandom.uuid}"
              end
            end
          end

          it 'creates as expected' do
            teacher = CustomTeacher.find_or_create(name: 'Dr. Harold Samuels')
            expect(teacher.custom_uuid).to include('DrHaroldSamuels_')
          end
        end

        it 'does not change the id property on match' do
          teacher1 = Teacher.find_or_create(name: 'Dr. Harold Samuels')
          teacher2 = Teacher.find_or_create(name: 'Dr. Harold Samuels')
          expect(teacher1.neo_id).to eq teacher2.neo_id
          expect(teacher1.id).to eq teacher2.id
        end

        it 'sets timestamps on create' do
          teacher = Teacher.find_or_create(name: 'Dr. Harold Samuels')
          expect(teacher.created_at).not_to be_nil
          expect(teacher.updated_at).not_to be_nil
        end

        context 'on match' do
          let(:original) { Teacher.find_or_create({name: 'Dr. Harold Samuels'}, age: 34) }

          before(:each) { original }

          it 'leaves timestamps intact' do
            teacher = Teacher.find_or_create(name: 'Dr. Harold Samuels')

            expect(teacher.created_at).to eq(original.created_at)
            expect(teacher.updated_at).to eq(original.updated_at)
          end

          it 'updates nothing' do
            teacher = Teacher.find_or_create({name: 'Dr. Harold Samuels'}, age: 0)

            expect(teacher.id).to eq(original.id)
            expect(teacher.name).to eq('Dr. Harold Samuels')
            expect(teacher.age).to eq(34)
          end
        end
      end
    end

    context 'samuels teaching soc 101 and 102 lessons' do
      before(:each) do
        samuels.lessons_teaching << ss101
        samuels.lessons_teaching << ss102
      end

      describe '`:as`' do
        context 'on a class' do
          it 'allows defining of a variable for class as start of QueryProxy chain' do
            expect(Teacher.as(:t).lessons.where(level: 101).pluck(:t)).to eq([samuels])
          end
        end

        context 'on an instance' do
          it 'allows defining of a variable for an instance as start of a QueryProxy chain' do
            expect(samuels.as(:s).pluck(:s).first).to eq samuels
          end

          it 'sets the `:caller` method' do
            expect(samuels.as(:s).source_object).to eq samuels
          end
        end
      end

      it 'allows for finds on associations' do
        expect(samuels.lessons_teaching.find(ss101.id)).to eq(ss101)
        expect { samuels.lessons_teaching.find(math101.id) }.to raise_error(Neo4j::RecordNotFound)
      end

      context 'samuels taught math 101 lesson' do
        before(:each) { samuels.lessons_taught << math101 }

        it 'returns only objects specified by association' do
          expect(samuels.lessons_teaching.to_a).to include(ss101, ss102)
          expect(samuels.lessons_teaching.count).to eq 2

          expect(samuels.lessons.to_a).to include(ss101, ss102, math101)
          expect(samuels.lessons.to_a.size).to eq 3
        end
      end
    end

    context 'bobby has teacher preferences' do
      before(:each) do
        bobby.favorite_teachers << samuels
        bobby.hated_teachers << othmar
      end

      it 'differentiates associations on the same model for the same class' do
        expect(bobby.favorite_teachers.to_a).to eq([samuels])
        expect(bobby.hated_teachers.to_a).to eq([othmar])
      end
    end

    context 'samuels is teaching soc 101 and geo 103' do
      before(:each) do
        samuels.lessons_teaching << ss101
        samuels.lessons_teaching << geo103
      end

      it 'allows params' do
        expect(Teacher.as(:t).where('t.name = {name}').params(name: 'Harold Samuels').to_a).to eq([samuels])

        expect(samuels.lessons_teaching(:lesson).where('lesson.level = {level}').params(level: 103).to_a).to eq([geo103])
      end

      it 'allows filtering on associations' do
        expect(samuels.lessons_teaching.where(level: 101).to_a).to eq([ss101])
      end

      it 'allows class methods on associations' do
        expect(samuels.lessons_teaching.level_number(101).to_a).to eq([ss101])

        expect(samuels.lessons_teaching.max_level).to eq(103)
        expect(samuels.lessons_teaching.where(subject: 'Social Studies').max_level).to eq(101)
      end

      it 'allows chaining of scopes and then class methods' do
        expect(samuels.lessons_teaching.level_number(101).max_level).to eq(101)
        expect(samuels.lessons_teaching.level_number(103).max_level).to eq(103)
      end

      context 'samuels also teaching math 201' do
        before(:each) do
          samuels.lessons_teaching << math101
        end

        it 'allows chaining of class methods and then scopes' do
          expect(samuels.lessons_teaching.ordered_by_subject.level_number(101).to_a).to eq([math101, ss101])
        end
      end

      describe '`labels` option when set false' do
        let(:with_labels) { proc { |target| target.lessons_teaching(:l, :r).students(:s, :sr).to_cypher } }
        let(:without_labels) { proc { |target| target.lessons_teaching(:l, :r, labels: false).students(:s, :sr, labels: false).to_cypher } }
        let(:expected_label_cypher) do
          proc do
            expect(query_with_labels).to include('[r:`LESSONS_TEACHING`]->(l:`Lesson`) MATCH (l)<-[sr:`is_enrolled_for`]-(s:`Student`)')
            expect(query_without_labels).to include('-[r:`LESSONS_TEACHING`]->(l) MATCH (l)<-[sr:`is_enrolled_for`]-(s)')
          end
        end

        context 'on instances' do
          let(:query_with_labels) { with_labels.call(samuels) }
          let(:query_without_labels) { without_labels.call(samuels) }

          it 'removes labels from Cypher' do
            expected_label_cypher.call
          end
        end

        context 'on class associations' do
          let(:query_with_labels) { with_labels.call(Teacher) }
          let(:query_without_labels) { without_labels.call(Teacher) }

          it 'removes labels from Cypher' do
            expected_label_cypher.call
          end
        end
      end
    end

    describe 'multiple labels' do
      before(:each) do
        stub_active_node_class('GitHub')

        stub_active_node_class('StackOverflow')

        stub_named_class('GitHubUser', GitHub) do
          self.mapped_label_name = 'User'
        end

        stub_named_class('StackOverflowUser', StackOverflow) do
          self.mapped_label_name = 'User'
        end
      end

      context 'one user each in GitHub and StackOverflow' do
        before(:each) do
          GitHubUser.create
          StackOverflowUser.create
        end

        it 'Should only find one of each' do
          expect(GitHubUser.count).to eq(1)
          expect(StackOverflowUser.count).to eq(1)
        end
      end
    end

    describe 'association chaining' do
      context 'othmar is teaching math 101' do
        before(:each) { othmar.lessons_teaching << math101 }

        context 'bobby is taking math 101, sandra is taking soc 101' do
          before(:each) { bobby.lessons << math101 }
          before(:each) { sandra.lessons << ss101 }

          it { expect(othmar.lessons_teaching.students.to_a).to eq([bobby]) }

          context 'bobby likes to read, sandra likes math' do
            before(:each) { bobby.interests << reading }
            before(:each) { sandra.interests << math }

            # Simple association chaining on three levels
            it { expect(othmar.lessons_teaching.students.interests.to_a).to eq([reading]) }
          end
        end

        context 'danny is also taking math 101' do
          before(:each) { danny.lessons << math101 }

          # Filtering on last association
          it { expect(othmar.lessons_teaching.students.where(age: 15).to_a).to eq([danny]) }

          # Mid-association variable assignment when filtering later
          it { expect(othmar.lessons_teaching(:lesson).students.where(age: 15).pluck(:lesson)).to eq([math101]) }

          # Two variable assignments
          it { expect(othmar.lessons_teaching(:lesson).students(:student).where(age: 15).pluck(:lesson, :student)).to eq([[math101, danny]]) }
        end

        describe 'on classes' do
          before(:each) do
            danny.lessons << math101
            rel = danny.lessons(:l, :r).pluck(:r).first
            rel[:grade] = 65
            rel.save

            bobby.lessons << math101
            rel = bobby.lessons(:l, :r).pluck(:r).first
            rel[:grade] = 71

            math101.teachers << othmar
            rel = math101.teachers(:t, :r).pluck(:r).first
            rel[:since] = 2001

            sandra.lessons << ss101
          end

          context 'students, age 15, who are taking level 101 lessons' do
            it { expect(Student.as(:student).where(age: 15).lessons(:lesson).where(level: 101).pluck(:student)).to eq([danny]) }
            it { expect(Student.where(age: 15).lessons(:lesson).where(level: '101').pluck(:lesson)).not_to eq([[othmar]]) }
            it do
              expect(Student.as(:student).where(age: 15).lessons(:lesson).where(level: 101).pluck(:student)).to eq(
                Student.as(:student).node_where(age: 15).lessons(:lesson).node_where(level: 101).pluck(:student)
              )
            end
          end

          context 'Students enrolled in math 101 with grade 65' do
            # with automatic identifier
            it { expect(Student.as(:student).lessons.rel_where(grade: 65).pluck(:student)).to eq([danny]) }

            # with manual identifier
            it { expect(Student.as(:student).lessons(:l, :r).rel_where(grade: 65).pluck(:student)).to eq([danny]) }

            # with multiple instances of rel_where
            it { expect(Student.as(:student).lessons(:l).rel_where(grade: 65).teachers(:t, :t_r).rel_where(since: 2001).pluck(:t)).to eq([othmar]) }
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
              it { expect(math101.teachers_pet(:l).lessons.where(level: 103)).to eq([geo103]) }
            end

            context 'on class' do
              # Lessons of level 101 that have a teachers pet, age 16, whose hated teachers include Ms Othmar... Who hates Mrs Othmar!?
              it { expect(Lesson.where(level: 101).teachers_pet(:s).where(age: 16).hated_teachers.where(name: 'Ms. Othmar').pluck(:s)).to eq([bobby]) }
            end
          end
        end
      end

      context 'othmar is also teaching math 201, brian is taking it' do
        before(:each) { othmar.lessons_teaching << math201 }
        before(:each) { brian.lessons << math201 }

        # Mid-association filtering
        it { expect(othmar.lessons_teaching.where(level: 201).students.to_a).to eq([brian]) }
      end
    end

    context 'othmar likes moster trucks more than samuels' do
      before(:each) do
        samuels.interests.create(monster_trucks, intensity: 1)
        othmar.interests.create(monster_trucks, intensity: 11)
      end

      # Should get both
      it { expect(monster_trucks.interested.count).to eq(2) }
      it { expect(monster_trucks.interested.to_a).to include(samuels, othmar) }

      # Variable assignment and filtering on a relationship
      it { expect(monster_trucks.interested(:person, :r).where('r.intensity < 5').pluck(:person)).to eq([samuels]) }

      it 'considers symbols as node fields for order' do
        expect(monster_trucks.interested(:person).order(:name).pluck(:person)).to eq([samuels, othmar])
        expect(monster_trucks.interested(:person, :r).order('r.intensity DESC').pluck(:person)).to eq([othmar, samuels])
      end
    end
  end

  describe 'Core::Query#proxy_as' do
    let(:core_query) do
      Neo4j::Session.current.query
        .match("(thing:CrazyLabel)-[weird_identifier:SOME_TYPE]->(other_end:DifferentLabel { size: 'grand' })<-[:REFERS_TO]-(s:Student)")
        .with(:other_end, :s)
    end

    let(:query_proxy) { Student.as(:s).lessons.where(subject: 'Math') }
    it 'builds a new QueryProxy object upon an existing Core::Query object' do
      part2 = 'MATCH (s)-[rel1:`is_enrolled_for`]->(result_lessons:`Lesson`) WHERE (result_lessons.subject = {result_lessons_subject})'
      combined_strings = "#{core_query.to_cypher} #{part2}"
      combined_query = core_query.proxy_as(Student, :s).lessons.where(subject: 'Math')

      expect(combined_query.to_cypher).to eq combined_strings
    end

    let(:brian) { Student.create(name: 'Brian') }
    let(:othmar) { Teacher.create(name: 'Ms Othmar') }
    let(:math201) { Lesson.create(subject: 'Math 201') }

    before do
      brian.lessons << math201
      math201.teachers << othmar
    end

    it 'safely handles the `result` identifier' do
      expect(brian.lessons.query.proxy_as(Lesson, :l).teachers.first).to eq othmar
    end

    describe 'optional matches' do
      let(:combined_query) { core_query.proxy_as(Student, :s, true).lessons.where(subject: 'Math') }
      let(:part2) { 'OPTIONAL MATCH (s)-[rel1:`is_enrolled_for`]->(result_lessons:`Lesson`) WHERE (result_lessons.subject = {result_lessons_subject})' }
      let(:combined_strings) { "#{core_query.to_cypher} #{part2}" }
      it 'can create an optional match' do
        expect(combined_query.to_cypher).to eq combined_strings
      end
    end
  end

  describe 'type conversion' do
    describe '#where' do
      before { [Date, DateTime, Time].each { |c| Teacher.property c.name.downcase.to_sym, type: c } }

      let(:date) { Date.today }
      let(:converted_date) { Time.utc(date.year, date.month, date.day).to_i }
      let(:datetime) { DateTime.now }
      let(:converted_datetime) { datetime.utc.to_i }
      let(:time) { Time.now }
      let(:converted_time) { time.utc.to_i }

      context 'with properties declared on the model' do
        it 'converts properties using the model\'s type converter' do
          expect(Teacher.where(date: date).to_cypher_with_params).to include(converted_date.to_s)
          expect(Teacher.where(datetime: datetime).to_cypher_with_params).to include(converted_datetime.to_s)
          expect(Teacher.where(time: time).to_cypher_with_params).to include(converted_time.to_s)
          expect(Teacher.where(age: '1').to_cypher_with_params).to include(':result_teacher_age=>1')
          expect(Student.where(likely_to_succeed: 'false').to_cypher_with_params).to include(':result_student_likely_to_succeed=>false')
        end

        context '...and values already in the destination format' do
          it 'uses the values as they are' do
            expect(Teacher.where(date: converted_date).to_cypher_with_params).to include(converted_date.to_s)
            expect(Teacher.where(datetime: converted_datetime).to_cypher_with_params).to include(converted_datetime.to_s)
            expect(Teacher.where(time: converted_time).to_cypher_with_params).to include(converted_time.to_s)
            expect(Teacher.where(age: 1).to_cypher_with_params).to include(':result_teacher_age=>1')
            expect(Student.where(likely_to_succeed: false).to_cypher_with_params).to include(':result_student_likely_to_succeed=>false')
          end
        end

        if !ENV['CI'] && RUBY_PLATFORM != 'java'
          context 'with Range values' do
            before do
              (1..10).each { |i| Student.create!(age: i) }
            end

            it 'does not convert' do
              expect(Student.where(age: (2..5)).count).to eq 4
            end
          end
        end

        context 'with Array values' do
          let(:today) { Date.today }

          before { Teacher.create(date: today) }

          it 'does not perform any conversion' do
            expect(Teacher.where(date: [today]).count).to eq 0
            expect(Teacher.where(date: [Time.utc(today.year, today.month, today.day).to_i]).count).to eq 1
          end
        end
      end

      context 'with properties not declared on the model' do
        it 'uses values as they are' do
          expect(Teacher.where(undeclared_date: date).to_cypher_with_params).not_to include(converted_date.to_s)
        end
      end

      context 'with an association using model_class: false' do
        before { Teacher.has_many :out, :unknowns, type: 'FOO', model_class: false }
        it 'does not raise an error' do
          expect { Teacher.unknowns.where(foo: 'bar').to_a }.not_to raise_error
        end
      end
    end

    describe 'Associations with `unique` set' do
      let(:from_node) { Student.create }
      let(:to_node)   { Interest.create }
      let(:first_props) { {score: 900} }
      let(:second_props) { {score: 1000} }
      let(:changed_props_create) { proc { from_node.interests.create(to_node, second_props) } }

      before do
        Student.has_many :out, :interests, options
        from_node.interests.create(to_node, first_props)
        expect(from_node.interests.count).to eq 1
      end

      context 'with `true` option' do
        let(:options) { {type: nil, unique: true} }
        it 'becomes :none' do
          expect(Neo4j::Shared::FilteredHash).to receive(:new).with(instance_of(Hash), :none).and_call_original
          changed_props_create.call
        end
      end

      context 'with :none open' do
        let(:options) { {type: nil, unique: :none} }

        it 'does not create additional rels, even when properties change' do
          expect do
            changed_props_create.call
          end.not_to change { from_node.interests.count }
        end
      end

      context 'with `:all` option' do
        let(:options) { {type: nil, unique: :all} }

        it 'creates additional rels when properties change' do
          expect { changed_props_create.call }.to change { from_node.interests.count }
        end
      end

      context 'with {on: [keys]} option' do
        let(:options) { {type: nil, unique: {on: :score}} }

        context 'and a listed property changes' do
          it 'creates a new rel' do
            expect { changed_props_create.call }.to change { from_node.interests.count }
          end
        end

        context 'and an unlisted property changes' do
          it 'does not create a new rel' do
            expect do
              from_node.interests.create(to_node, first_props.merge(default: 'some other value'))
            end.not_to change { from_node.interests.count }
          end
        end
      end
    end

    describe 'rel_methods' do
      before do
        student = Student.create
        math = Lesson.create(subject: 'Math')
        science = Lesson.create(subject: 'Science')
        IsEnrolledFor.create!(from_node: student, to_node: math, grade: 65)
        IsEnrolledFor.create!(from_node: student, to_node: science, grade: 99)
      end

      describe '#rel_where' do
        context 'with a rel_class present' do
          let(:lesson65) { Student.lessons.rel_where(grade: '65').to_a }
          let(:lesson99) { Student.lessons.rel_where(grade: '99'.to_f).to_a }

          it 'type converts when possible' do
            expect(lesson65.count).to eq 1
            expect(lesson65.first.subject).to eq 'Math'
            expect(lesson99.count).to eq 1
            expect(lesson99.first.subject).to eq 'Science'
          end
        end
      end

      describe '#rel_order' do
        it 'allows ordering by relationships with rel_order' do
          expect(Student.lessons(:l, :rel).rel_order(:grade).pluck('rel.grade')).to eq([65, 99])
        end
      end
    end
  end

  describe 'association query behavior' do
    let!(:ss101) { Lesson.create(subject: 'Social Studies', level: 101) }
    let!(:mrjames) { Teacher.create(name: 'Mr. James') }

    context 'Mr. James teaches Social Studies' do
      before { ss101.teachers << mrjames }

      it 'does not get confused when associations have been cached' do
        lesson = Lesson.find(ss101.id)
        expect(lesson.teachers.to_a).to eq([mrjames])

        expect(lesson.teachers.where(name: 'aoeuo')).to be_empty
        expect(lesson.teachers.where(name: 'aoeuo').to_a).to be_empty
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
