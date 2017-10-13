describe 'query_proxy_methods' do
  # goofy names to differentiate from same classes used elsewhere
  before(:each) do
    clear_model_memory_caches

    stub_active_node_class('Student') do
      property :name
      has_many :out, :lessons, model_class: 'Lesson', rel_class: 'EnrolledIn'
      has_many :out, :things, model_class: false, type: 'lessons'
    end

    stub_active_node_class('Lesson') do
      property :name
      has_many :in, :students, model_class: 'Student', rel_class: 'EnrolledIn'
      has_many :in, :teachers, model_class: 'Teacher', origin: :lessons
    end

    stub_active_node_class('Teacher') do
      property :name
      property :age, type: Integer
      has_many :out, :lessons, model_class: 'Lesson', type: 'teaching_lesson'
    end

    stub_active_node_class('EmptyClass') do
      has_many :out, :lessons, type: nil, model_class: 'Lesson'
    end

    stub_active_rel_class('EnrolledIn') do
      from_class 'Student'
      to_class 'Lesson'
      type 'lessons'

      property :absence_count, type: Integer, default: 0

      after_destroy :destroy_called

      def destroy_called
      end
    end
  end
  let!(:jimmy)    { Student.create(name: 'Jimmy') }
  let!(:math)     { Lesson.create(name: 'math') }
  let!(:science)  { Lesson.create(name: 'science') }
  let!(:mr_jones) { Teacher.create }
  let!(:mr_adams) { Teacher.create }

  shared_examples 'is initialized correctly with associations' do
    it { should be_a(Neo4j::ActiveNode) }
    its(:name) { should eq(student_name) }
    its(:lessons) { should include(philosophy) }
  end

  shared_examples 'finds existing records or initializes them with relations' do
    let(:frank)       { Student.create(name: 'Frank') }
    let(:philosophy)  { Lesson.create(name: 'philosophy') }
    before { philosophy.students << frank }

    context 'when it already exists' do
      let(:student_name) { 'Frank' }

      it_should_behave_like 'is initialized correctly with associations'
      it { should be_persisted }
    end

    context 'when it\'s a new record' do
      let(:student_name) { 'Jacob' }

      it_should_behave_like 'is initialized correctly with associations'
      it { should_not be_persisted }
      it 'can be saved' do
        expect { subject.save }.to change { philosophy.reload.students.count }.by(1)
      end
    end
  end

  shared_examples 'is initialized correctly with attributes' do
    it { should be_a(Neo4j::ActiveNode) }
    its(:name) { should eq(teacher_name) }
    its(:age) { should eq(teacher_age) }
  end

  shared_examples 'finds existing records or initializes them with attributes' do
    let!(:old_emily)   { Teacher.create(name: 'Emily', age: 72) }
    let!(:young_emily) { Teacher.create(name: 'Emily', age: 24) }

    context 'when it already exists' do
      let(:teacher_name) { 'Emily' }
      let(:teacher_age)  { 24 }

      it_should_behave_like 'is initialized correctly with attributes'
      it { should be_persisted }
    end

    context 'when it\'s a new record' do
      let(:teacher_name) { 'Emily' }
      let(:teacher_age)  { 37 }

      it_should_behave_like 'is initialized correctly with attributes'
      it { should_not be_persisted }
      it 'can be saved' do
        expect { subject.save }.to change { Teacher.count }.by(1)
        subject.destroy
      end
    end
  end

  describe 'find_or_create_by' do
    let(:emily)       { Student.create(name: 'Emily') }
    let(:philosophy)  { Lesson.create(name: 'philosophy') }
    let(:mixology) { Lesson.create(name: 'mixology') }
    before do
      philosophy.students << jimmy
    end

    it 'returns the correct node if it can be found' do
      expect(philosophy.students.find_or_create_by(name: jimmy.name)).to eq(jimmy)
    end

    it 'creates and associates a new node if one is not found' do
      expect(philosophy.students.where(name: 'Rebecca').blank?).to be_truthy
      expect { philosophy.students.find_or_create_by(name: 'Rebecca') }.to change { Student.all.count }
      expect(philosophy.students.where(name: 'Rebecca').blank?).to be_falsey
    end

    it 'returns the node after creating' do
      expect(philosophy.students.find_or_create_by(name: 'Jacob')).to be_a(Neo4j::ActiveNode)
    end

    it 'does not look outside of scope' do
      mixology.students.find_or_create_by(name: 'Emily')

      expect { philosophy.students.find_or_create_by(name: 'Emily') }.to change { Student.all.count }
    end
  end

  describe 'find_or_initialize_by on an association' do
    subject { philosophy.students.find_or_initialize_by(name: student_name) }

    it_should_behave_like 'finds existing records or initializes them with relations'
  end

  describe 'find_or_initialize_by on query proxy' do
    subject { Teacher.where(name: teacher_name).find_or_initialize_by(age: teacher_age) }
    it_should_behave_like 'finds existing records or initializes them with attributes'

    context 'when a block is passed' do
      let(:teacher_name) { 'Donna' }
      let(:teacher_age)  { 92 }

      subject { Teacher.where(name: 'Emily').find_or_initialize_by(age: teacher_age) { |t| t.name = teacher_name } }

      it_should_behave_like 'is initialized correctly with attributes'
      it { should_not be_persisted }
    end
  end

  describe 'first_or_initialize on relations' do
    subject { philosophy.students.where(name: student_name).first_or_initialize }

    it_should_behave_like 'finds existing records or initializes them with relations'
  end

  describe 'first_or_initialize on query proxy' do
    subject { Teacher.where(name: teacher_name, age: teacher_age).first_or_initialize }

    it_should_behave_like 'finds existing records or initializes them with attributes'

    context 'when a block is passed' do
      let(:teacher_name) { 'Donna' }
      let(:teacher_age)  { 92 }

      subject { Teacher.where(name: 'Emily', age: teacher_age).first_or_initialize { |t| t.name = teacher_name } }

      it_should_behave_like 'is initialized correctly with attributes'
      it { should_not be_persisted }
    end
  end

  describe 'first and last' do
    it 'returns objects across multiple associations' do
      jimmy.lessons << science
      science.teachers << mr_adams
      expect(jimmy.lessons.teachers.first).to eq mr_adams
      expect(mr_adams.lessons.students.last).to eq jimmy
    end
  end

  describe 'include?' do
    it 'correctly reports when a node is included in a query result' do
      jimmy.lessons << science
      science.teachers << mr_adams
      expect(jimmy.lessons.include?(science)).to be_truthy
      expect(jimmy.lessons.include?(math)).to be_falsey
      expect(jimmy.lessons.teachers.include?(mr_jones)).to be_falsey
      expect(jimmy.lessons.where(name: 'science').teachers.include?(mr_jones)).to be_falsey
      expect(jimmy.lessons.where(name: 'science').teachers.include?(mr_adams)).to be_truthy
      expect(Teacher.all.include?(mr_jones)).to be_truthy
      expect(Teacher.all.include?(math)).to be_falsey
    end

    it 'works with multiple relationships to the same object' do
      jimmy.lessons << science
      jimmy.lessons << science
      expect(jimmy.lessons.include?(science)).to be_truthy
    end

    it 'returns correctly when model_class is false' do
      woodworking = Lesson.create(name: 'woodworking')
      expect(jimmy.things.include?(woodworking)).to be_falsey
      jimmy.lessons << woodworking
      expect(jimmy.things.include?(woodworking)).to be_truthy
      woodworking.destroy
    end

    it 'allows you to check for an identifier in the middle of a chain' do
      jimmy.lessons << science
      science.teachers << mr_adams
      expect(Lesson.as(:l).students.where(name: 'Jimmy').include?(science, :l)).to be_truthy
    end

    it 'can find by primary key/uuid' do
      expect(jimmy.lessons.include?(science.id)).to be_falsey
      jimmy.lessons << science
      expect(jimmy.lessons.include?(science.id)).to be_truthy
      expect(jimmy.lessons.include?(id_property_value(science))).to be_truthy
      expect(jimmy.lessons.include?(science)).to be_truthy
    end

    it 'does not break when the query has been ordered' do
      expect(jimmy.lessons.order(created_at: :desc).include?(science)).to eq jimmy.lessons.include?(science)
    end
  end

  describe 'exists?' do
    context 'class methods' do
      it 'can run by a class' do
        expect(EmptyClass.empty?).to be_truthy
        expect(Lesson.empty?).to be_falsey
      end

      it 'does not fail from an ordered context' do
        expect(Lesson.order(:name).empty?).to eq false
      end

      it 'can be called with a property and value' do
        expect(Lesson.exists?(name: 'math')).to eq true
        expect(Lesson.exists?(name: 'boat repair')).to eq false
      end

      it 'can be called on the class with a neo_id' do
        expect(Lesson.exists?(math.neo_id)).to eq true
        expect(Lesson.exists?(8_675_309)).to eq false
      end

      it 'can be called on a class with a primary key value' do
        expect(Lesson.exists?(math.id)).to eq true
        expect(Lesson.exists?('this_other_value')).to eq false
      end

      it 'raises an error if something other than a neo id is given' do
        expect { Lesson.exists?(:fooooo) }.to raise_error(Neo4j::InvalidParameterError)
      end
    end

    context 'QueryProxy methods' do
      it 'can be called on a query' do
        expect(Lesson.where(name: 'history').exists?).to eq false
        expect(Lesson.where(name: 'math').exists?).to eq true
      end

      it 'can be called with property and value' do
        expect(jimmy.lessons.exists?(name: 'science')).to eq false
        jimmy.lessons << science
        expect(jimmy.lessons.exists?(name: 'science')).to eq true
        expect(jimmy.lessons.exists?(name: 'bomb disarming')).to eq false
      end

      it 'can be called with a neo_id' do
        expect(Lesson.where(name: 'math').exists?(math.neo_id)).to eq true
        expect(Lesson.where(name: 'math').exists?(science.neo_id)).to eq false
      end

      it 'can be called with a primary key' do
        expect(Lesson.where(name: 'math').exists?(math.id)).to eq true
        expect(Lesson.where(name: 'math').exists?(science.id)).to eq false
      end

      it 'is called by :blank? and :empty?' do
        expect(jimmy.lessons.blank?).to eq true
        expect(jimmy.lessons.empty?).to eq true
        jimmy.lessons << science
        expect(jimmy.lessons.blank?).to eq false
        expect(jimmy.lessons.empty?).to eq false
      end

      it 'does not fail from an ordered context' do
        expect(jimmy.lessons.order(:name).blank?).to eq true
        expect(jimmy.lessons.order(:name).empty?).to eq true
      end
    end
  end

  describe 'count' do
    before(:each) do
      [Student, Lesson].each(&:delete_all)

      @john = Student.create(name: 'John')
      @history = Lesson.create(name: 'history')
      3.times { @john.lessons << @history }
    end

    it 'tells you the number of matching objects' do
      expect(@john.lessons.count).to eq(3)
    end

    it 'can tell you the number of distinct matching objects' do
      expect(@john.lessons.count(:distinct)).to eq 1
    end

    it 'raises an exception if a bad parameter is passed' do
      expect { @john.lessons.count(:foo) }.to raise_error(Neo4j::InvalidParameterError)
    end

    it 'works on an object earlier in the chain' do
      expect(Student.as(:s).lessons.where(name: 'history').count(:distinct, :s)).to eq 1
    end

    it 'works with order clause' do
      expect { Student.order(name: :asc).count }.not_to raise_error
    end

    it 'is aliased by length and size' do
      expect(@john.lessons.size).to eq(3)
      expect(@john.lessons.length).to eq(3)
    end

    context 'with limit' do
      before do
        Student.delete_all
        10.times { Student.create }
      end

      it 'adds a :with and returns the limited count' do
        expect(Student.as(:s).limit(5).count).to eq 5
        expect(Student.as(:s).limit(11).count).to eq 10
      end
    end
  end

  describe 'distinct' do
    let(:frank)       { Student.create(name: 'Frank') }
    let(:bill) { Teacher.create(name: 'Bill') }
    let(:philosophy)  { Lesson.create(name: 'philosophy') }
    let(:science)     { Lesson.create(name: 'science') }
    before do
      philosophy.students << frank
      science.students << frank
      philosophy.teachers << bill
      science.teachers << bill
    end

    context 'when building the query' do
      before do
        @subscription = Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query do |query|
          expect(query).to include('DISTINCT')
        end
      end

      after do
        ActiveSupport::Notifications.unsubscribe(@subscription) if @subscription
      end

      it 'adds distinct to a select query' do
        frank.lessons.teachers.distinct.to_a
      end

      it 'branch perserves distinct in a select query' do
        frank.lessons.teachers.distinct.branch { lessons }.to_a
      end

      it 'with_associations perserves distinct in a select query' do
        frank.lessons.teachers.distinct.with_associations(:lessons).to_a
      end
    end

    it 'counts values without duplicates' do
      expect(frank.lessons.teachers.count).to eq(2)
      expect(frank.lessons.teachers.distinct.count).to eq(1)
    end

    it 'counts values without duplicates in a branch query' do
      expect(frank.lessons.teachers.distinct.branch { lessons }.count).to eq(1)
    end

    it 'selects values without duplicates' do
      expect(frank.lessons.teachers.distinct.to_a).to eq(frank.lessons.teachers.to_a.uniq)
    end
  end

  describe 'query counts for count, size, and length' do
    describe 'size' do
      it 'always queries' do
        proxy = Student.all
        expect_queries(1) { proxy.count }
        expect_queries(1) { proxy.to_a }
        expect_queries(1) { proxy.count }
      end
    end

    describe 'size' do
      it 'always queries' do
        proxy = Student.all
        expect_queries(1) { proxy.size }
        expect_queries(1) { proxy.to_a }
        expect_queries(0) { proxy.size }
      end
    end

    # Always loads the data
    describe 'length' do
      it 'always queries' do
        proxy = Student.all
        expect_queries(1) { proxy.length }
        expect_queries(0) { proxy.to_a }
        expect_queries(0) { proxy.length }
      end
    end
  end

  describe '#update_all' do
    let!(:jimmy_clone) { Student.create(name: 'Jimmy') }
    let!(:john)        { Student.create(name: 'John') }

    let(:changing_students) { Student.where(name: 'Bob') }

    it 'updates all students' do
      expect(Student.update_all(name: 'Bob')).to eq(Student.count)
      expect(Student.all.map(&:name)).to be_all { |age| age == 'Bob' }
    end

    it 'updates students' do
      expect do
        expect(Student.as(:p).where('p.name = "Jimmy"').update_all(name: 'Bob')).to eq(2)
      end.to change(changing_students, :count).by(2)
    end

    it 'updates people with age < 30 (using string parameter)' do
      expect do
        expect(Student.as(:p).where('p.name = "Jimmy"').update_all('p.name = {new_name}', new_name: 'Bob')).to eq(2)
      end.to change(changing_students, :count).by(2)
    end

    it 'updates nothing when matching nothing' do
      expect do
        expect(Student.as(:n).where('n.name = "Frank"').update_all(name: 'Bob')).to eq(0)
      end.not_to change(changing_students, :count)
    end

    it 'raises error on invalid argument' do
      expect do
        Student.update_all(7)
      end.to raise_error ArgumentError
    end
  end

  describe '#update_all_rels' do
    before do
      science.students << jimmy
      math.students << jimmy
    end

    it 'updates all jimmy\'s lessions absence' do
      count = Student.all.match_to(jimmy).lessons(:l)
                     .update_all_rels(absence_count: 3)
      expect(count).to eq(2)
    end

    it 'updates all jimmy\'s lessions absence (with string parameter)' do
      count = Student.all.match_to(jimmy).lessons(:l)
                     .update_all_rels('rel1.absence_count = 3')
      expect(count).to eq(2)
    end

    it 'raises error on invalid argument' do
      expect do
        Student.all.match_to(jimmy).lessons(:l).update_all(7)
      end.to raise_error ArgumentError
    end
  end

  describe 'delete_all' do
    it 'deletes from Model' do
      Student.delete_all
      expect(Student.count).to eq(0)
    end

    it 'deletes from Model.all' do
      Student.all.delete_all
      expect(Student.count).to eq(0)
    end

    context 'Student has lessons which have teachers' do
      before do
        [Student, Lesson, Teacher].each(&:delete_all)
        @tom = Student.create(name: 'Tom')
        @math = Lesson.create(name: 'Math')
        @science = Lesson.create(name: 'Science')
        @adams = Teacher.create(name: 'Mr Adams')
        @johnson = Teacher.create(name: 'Mrs Johnson')
        @tom.lessons << @math
        @tom.lessons << @science
        @math.teachers << @adams
        @science.teachers << @johnson
      end

      it 'removes the last link in the QueryProxy chain' do
        expect(@tom.lessons.teachers.include?(@adams)).to be_truthy
        @tom.lessons.teachers.delete_all
        expect(@adams.exist?).to be_falsey
        expect(@johnson.exist?).to be_falsey
        expect(@tom.lessons.teachers).to be_empty
      end

      it 'does not touch earlier portions of the chain' do
        expect(@tom.lessons.include?(@math)).to be_truthy
        @tom.lessons.teachers.delete_all
        expect(@math.persisted?).to be_truthy
      end

      it 'works when called from a class' do
        expect(@tom.lessons.teachers.include?(@adams)).to be_truthy
        Student.all.lessons.teachers.delete_all
        expect(@adams.exist?).to be_falsey
      end

      it 'can target a specific identifier' do
        @tom.lessons(:l).teachers.where(name: 'Mr Adams').delete_all(:l)
        expect(@tom.lessons.include?(@math)).to be_falsey
        expect(@math.exist?).to be false
        expect(@tom.lessons.include?(@science)).to be_truthy
      end

      it 'can target relationships' do
        @tom.lessons(:l, :r).teachers.where(name: 'Mr Adams').delete_all(:r)
        expect(@tom.lessons.include?(@math)).to be_falsey
        expect(@math).to be_persisted
      end
    end
  end

  describe 'limit_value' do
    it 'returns nil when limit is not specified' do
      expect(Student.all.limit_value).to be_nil
    end

    it 'returns the limit number when set' do
      expect(Student.all.limit(10).limit_value).to eq 10
    end
  end

  describe 'match_to and first_rel_to' do
    before(:each) do
      @john = Student.create(name: 'Paul')
      @history = Lesson.create(name: 'history')
      @math = Lesson.create(name: 'math')
      @john.lessons << @history
    end

    describe 'match_to' do
      it 'returns a QueryProxy object' do
        expect(@john.lessons.match_to(@history)).to be_a(Neo4j::ActiveNode::Query::QueryProxy)
        expect(@john.lessons.match_to(@history.id)).to be_a(Neo4j::ActiveNode::Query::QueryProxy)
        expect(@john.lessons.match_to(nil)).to be_a(Neo4j::ActiveNode::Query::QueryProxy)
      end

      context 'with a valid node' do
        it 'generates a match to the given node' do
          expect(@john.lessons.match_to(@history).to_cypher).to include('WHERE (ID(result_lessons) =')
        end

        it 'matches the object' do
          expect(@john.lessons.match_to(@history).limit(1).first).to eq @history
        end
      end

      context 'with an id' do
        it 'generates cypher using the primary key' do
          expect(@john.lessons.match_to(@history.id).to_cypher).to include(if Lesson.primary_key == :neo_id
                                                                             'WHERE (ID(result_lessons) ='
                                                                           else
                                                                             'WHERE (result_lessons.uuid ='
                                                                           end)
        end

        it 'matches' do
          expect(@john.lessons.match_to(@history.id).limit(1).first).to eq @history
        end
      end

      context 'with an array' do
        context 'of nodes' do
          after(:each) do
            @john.lessons.first_rel_to(@math).destroy
          end

          it 'generates cypher using IN with the IDs of contained nodes' do
            expect(@john.lessons.match_to([@history, @math]).to_cypher).to include('ID(result_lessons) IN')
            expect(@john.lessons.match_to([@history, @math]).to_a).to eq [@history]
            @john.lessons << @math
            expect(@john.lessons.match_to([@history, @math]).to_a.size).to eq 2
            expect(@john.lessons.match_to([@history, @math]).to_a).to include(@history, @math)
          end
        end

        context 'of IDs' do
          it 'allows an array of IDs' do
            expect(@john.lessons.match_to([@history.id]).to_a).to eq [@history]
          end
        end
      end

      context 'with a null object' do
        it 'generates cypher with 1 = 2' do
          expect(@john.lessons.match_to(nil).to_cypher).to include('WHERE (1 = 2')
        end

        it 'matches nil' do
          expect(@john.lessons.match_to(nil).first).to be_nil
        end
      end

      context 'on Model.all' do
        it 'works with a node' do
          expect(Lesson.all.match_to(@history).first).to eq @history
        end

        it 'works with an id' do
          expect(Lesson.all.match_to(@history.id).first).to eq @history
        end
      end

      describe 'complex chains' do
        before do
          jimmy.lessons << math
          math.teachers << mr_jones
          mr_jones.age = 40
          mr_jones.save

          jimmy.lessons << science
          science.teachers << mr_adams
          mr_adams.age = 50
          mr_adams.save
        end

        it 'works with a chain starting with `all`' do
          expect(Student.all.match_to(jimmy).lessons(:l).match_to(math).teachers.where(age: 40).first).to eq mr_jones
        end
      end
    end

    describe 'first_rel_to' do
      it 'returns the first relationship across a QueryProxy chain to a given node' do
        expect(@john.lessons.first_rel_to(@history)).to be_a EnrolledIn
      end

      it 'returns nil when nothing matches' do
        expect(@john.lessons.first_rel_to(@math)).to be_nil
      end
    end

    # also aliased as `all_rels_to`
    describe 'rels_to' do
      before { 3.times { @john.lessons << @history } }
      it 'returns all relationships across a QueryProxy chain to a given node' do
        all_rels = @john.lessons.rels_to(@history)
        expect(all_rels).to be_a(Enumerable)
        expect(all_rels.count).to eq @john.lessons.match_to(@history).count
        @john.lessons.all_rels_to(@history).map(&:destroy)
        @john.association_proxy_cache.clear
        expect(@john.lessons.all_rels_to(@history)).to be_empty
      end
    end

    describe 'as' do
      it 'changes query variable' do
        query = Student.as(:stud)
        expect(query.to_cypher).to include('(stud:`Student`)')
        query.to_a
      end

      it 'keeps the current context' do
        query = Student.where(name: 'John').as(:stud)
        expect(query.to_cypher).to include('(stud:`Student`)', ' WHERE ')
        query.to_a
      end

      it 'keeps the current context with associations' do
        query = Student.all.lessons.as(:less)
        expect(query.to_cypher).to include('`Student`)', '(less:`Lesson`)')
        query.to_a
      end
    end

    describe 'delete, destroy' do
      before { @john.lessons << @history unless @john.lessons.include?(@history) }

      describe 'delete' do
        it 'removes relationships between a node and the last link of the QP chain from the server' do
          expect_any_instance_of(EnrolledIn).not_to receive(:destroy_called)
          expect(@john.lessons.include?(@history)).to be_truthy
          @john.lessons.delete(@history)
          expect(@john.lessons.include?(@history)).to be_falsey

          # let's just be sure it's not deleting the nodes...
          expect(@john).to be_persisted
          expect(@history).to be_persisted
        end

        it 'accepts an array' do
          @john.lessons << @math
          @john.lessons.delete([@math, @history])
          expect(@john.lessons.to_a).not_to include(@math, @history)
        end
      end

      describe 'destroy' do
        it 'returns relationships and destroys them in Ruby, executing callbacks in the process' do
          expect(@john.lessons.include?(@history)).to be_truthy
          expect_any_instance_of(EnrolledIn).to receive(:destroy_called)
          @john.lessons.destroy(@history)
          expect(@john.lessons.include?(@history)).to be_falsey

          # let's just be sure it's not deleting the nodes...
          expect(@john).to be_persisted
          expect(@history).to be_persisted
        end

        it 'accepts an array' do
          @john.lessons << @math
          @john.lessons.destroy([@math, @history])
          expect(@john.lessons.to_a).not_to include(@math, @history)
        end
      end
    end
  end

  context 'matching by relations' do
    before(:each) do
      [Student, Lesson, Teacher].each(&:delete_all)

      @john = Student.create(name: 'John')
      @bill = Student.create(name: 'Bill')
      @frank = Student.create(name: 'Frank')
      @history = Lesson.create(name: 'history')
      @john.lessons << @history
      EnrolledIn.create(from_node: @frank, to_node: @history, absence_count: 10)
    end

    describe 'having_rel' do
      it 'returns students having at least a lesson' do
        expect(Student.all.having_rel(:lessons)).to contain_exactly(@john, @frank)
      end

      it 'returns students having at least a lesson with no absences' do
        expect(Student.all.having_rel(:lessons, absence_count: 0)).to contain_exactly(@john)
      end

      it 'returns no student when absence is negative' do
        expect(Student.all.having_rel(:lessons, absence_count: -1)).to eq([])
      end

      it 'returns no lesson having teacher, since there\'s none' do
        expect(Lesson.all.having_rel(:teachers)).to eq([])
      end

      it 'raises ArgumentError when passing a missing relation' do
        expect { Lesson.all.having_rel(:friends) }.to raise_error(ArgumentError)
      end
    end

    describe 'not_having_rel' do
      it 'returns students having at least a lesson' do
        expect(Student.all.not_having_rel(:lessons)).to contain_exactly(@bill)
      end

      it 'returns students having at least a lesson with no absences' do
        expect(Student.all.not_having_rel(:lessons, absence_count: 0)).to contain_exactly(@bill, @frank)
      end

      it 'returns no lesson having no students, since there\'s none' do
        expect(Lesson.all.not_having_rel(:students)).to eq([])
      end

      it 'raises ArgumentError when passing a missing relation' do
        expect { Lesson.all.not_having_rel(:friends) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'branch' do
    before(:each) do
      [Student, Lesson, Teacher].each(&:delete_all)

      @john = Student.create(name: 'John')
      @bill = Student.create(name: 'Bill')
      @history = Lesson.create(name: 'history')
      @jim = Teacher.create(name: 'Jim', age: 40)
      3.times { @john.lessons << @history }
      @history.teachers << @jim
    end

    it 'returns a QueryProxy object' do
      expect(@john.lessons.branch { teachers }).to be_a(Neo4j::ActiveNode::Query::QueryProxy)
    end

    it 'keeps identity to the external chain' do
      expect(@john.lessons(:l).branch { teachers(:t) }.identity).to eq(:l)
    end

    it 'queries lessions' do
      expect(@john.lessons(:l).branch { teachers(:t) }.to_a.first).to be_a(Lesson)
    end

    it 'applies the query in the block' do
      expect(@john.lessons.branch { teachers(:t) }.to_cypher).to include('(t:`Teacher`)')
    end

    it 'returns only records matching the relation' do
      students_with_lessons = Student.all.branch { lessons }.to_a
      expect(students_with_lessons).to include(@john)
      expect(students_with_lessons).not_to include(@bill)
    end

    it 'uses the right cypher variable through the branch' do
      job = Teacher.create(name: 'Job', age: 28)
      jil = Teacher.create(name: 'Jil', age: 35)
      sceince = Lesson.create(name: 'Sceince', teachers: [job])
      muth = Lesson.create(name: 'Muth', teachers: [jil])
      jummy = Student.create(name: 'Jummy', lessons: [sceince, muth])

      Student.create(name: 'Rundom')

      result = jummy.lessons.branch { teachers.where(age: 28) }.students
      # We should only get Jummy.  Failure in choosing the identity would give all
      expect(result).to eq [jummy]
    end

    it 'raises LocalJumpError when no block is passed' do
      expect { @john.lessons.branch }.to raise_error LocalJumpError
    end
  end

  describe 'optional' do
    before(:each) do
      delete_db

      @lauren = Student.create(name: 'Lauren')
      @math = Lesson.create(name: 'Math')
      @science = Lesson.create(name: 'Science')
      @johnson = Teacher.create(name: 'Mr. Johnson', age: 40)
      @clancy = Teacher.create(name: 'Mr. Clancy', age: 50)

      @lauren.lessons << [@math, @science]
      @math.teachers << @johnson
      @science.teachers << @clancy
    end

    it 'starts a new optional match' do
      result = @lauren.lessons(:l).optional(:teachers, :t).where(age: 40).query.order(l: :name).pluck('distinct l, t')

      expect(result).to eq [[@math, @johnson],
                            [@science, nil]]
    end
  end

  describe '#inspect' do
    before(:each) do
      delete_db

      Student.create(name: 'Lauren')
      Student.create(name: 'Bob')
      Student.create(name: 'Bill')
    end

    context 'when inspecting a query proxy' do
      let(:query_proxy) { Student.all }
      let(:inspected_elements) { query_proxy.inspect }

      it 'returns the list of resulting elements' do
        expect(inspected_elements).to include('#<QueryProxy Student')
        expect(inspected_elements).to include(query_proxy.to_a.inspect)
      end
    end
  end
end
