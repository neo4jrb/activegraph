require 'spec_helper'

describe '_classname property' do
  before(:each) do
    Neo4j::ActiveRel::Types::WRAPPED_CLASSES.clear

    stub_active_node_class('Student') do
      property :name

      has_many :out, :lessons, model_class: 'Lesson', rel_class: 'EnrolledIn'
      has_many :out, :lessons_with_type, model_class: 'Lesson', rel_class: 'StudentLesson'
      has_many :out, :lessons_with_classname, model_class: 'Lesson', rel_class: 'EnrolledInClassname'
    end

    stub_active_node_class('Lesson') do
      property :subject
    end

    stub_active_node_class('NodeWithClassname') do
      set_classname
    end

    stub_active_rel_class('EnrolledIn') do
      from_class 'Student'
      to_class 'Lesson'
    end

    stub_active_rel_class('StudentLesson') do
      from_class 'Student'
      to_class 'Lesson'
      type 'ENROLLED_IN_SPECIAL'
    end

    stub_active_rel_class('EnrolledInClassname') do
      from_class 'Student'
      to_class 'Lesson'
      type 'ENROLLED_IN'
      set_classname
    end
  end

  before(:each) do
    @billy    = Student.create(name: 'Billy')
    @science  = Lesson.create(subject: 'Science')
    @math     = Lesson.create(subject: 'Math')
    @history  = Lesson.create(subject: 'History')

    EnrolledIn.create(from_node: @billy, to_node: @science)
    StudentLesson.create(from_node: @billy, to_node: @math)
    EnrolledInClassname.create(from_node: @billy, to_node: @history)
  end

  after(:each) do
    [Lesson, Student].each(&:delete_all)
  end

  # these specs will fail if tested against Neo4j < 2.1.5
  describe 'neo4j 2.1.5+' do
    describe 'ActiveNode models' do
      it 'does not add _classname to nodes by default' do
        expect(@billy._persisted_obj.props).not_to have_key(:_classname)
      end

      it 'adds _classname when `set_classname` is called' do
        node = NodeWithClassname.create
        expect(node._persisted_obj.props).to have_key(:_classname)
      end
    end

    context 'without _classname or type' do
      let(:rel) { @billy.lessons.first_rel_to(@science) }

      it 'does not add a classname property' do
        expect(rel._persisted_obj.props).not_to have_key(:_classname)
      end

      it 'is the expected type' do
        expect(rel).to be_a(EnrolledIn)
      end
    end

    context 'without classname, with type' do
      let(:rel) { @billy.lessons_with_type.first_rel_to(@math) }

      it 'does not add a classname property' do
        expect(rel._persisted_obj.props).not_to have_key(:_classname)
      end

      it 'is the expected type' do
        expect(rel).to be_a(StudentLesson)
      end
    end

    context 'with classname and type' do
      let(:rel) { @billy.lessons_with_classname.first_rel_to(@history) }

      it 'adds a classname property' do
        expect(rel._persisted_obj.props).to have_key(:_classname)
      end

      it 'is the expected type' do
        expect(rel).to be_a(EnrolledInClassname)
      end
    end
  end

  describe 'neo4j 2.1.4' do
    let(:session) { Neo4j::Session.current }
    before do
      expect(session).to receive(:version).at_least(1).times.and_return('2.1.4')

      @billy    = Student.create(name: 'Billy')
      @science  = Lesson.create(subject: 'Science')
      @math     = Lesson.create(subject: 'Math')
      @history  = Lesson.create(subject: 'History')

      EnrolledIn.create(from_node: @billy, to_node: @science)
      StudentLesson.create(from_node: @billy, to_node: @math)
      EnrolledInClassname.create(from_node: @billy, to_node: @history)
    end

    it 'always adds _classname and is of the expected class' do
      expect(@billy._persisted_obj.props).to have_key(:_classname)

      science_rel = @billy.lessons.first_rel_to(@science)
      expect(science_rel._persisted_obj.props).to have_key(:_classname)
      expect(science_rel).to be_a(EnrolledIn)

      math_rel = @billy.lessons_with_type.first_rel_to(@math)
      expect(math_rel._persisted_obj.props).to have_key(:_classname)
      expect(math_rel).to be_a(StudentLesson)

      history_rel = @billy.lessons_with_classname.first_rel_to(@history)
      expect(history_rel._persisted_obj.props).to have_key(:_classname)
      expect(history_rel).to be_a(EnrolledInClassname)
    end
  end
end
