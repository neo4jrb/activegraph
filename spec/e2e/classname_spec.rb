require 'spec_helper'

describe '_classname property' do
  module ClassnameSpec
    class Student
      include Neo4j::ActiveNode
      property :name

      has_many :out, :lessons, model_class: 'ClassnameSpec::Lesson', rel_class: 'ClassnameSpec::EnrolledIn'
      has_many :out, :lessons_with_type, model_class: 'ClassnameSpec::Lesson', rel_class: 'ClassnameSpec::StudentLesson'
      has_many :out, :lessons_with_classname, model_class: 'ClassnameSpec::Lesson', rel_class: 'ClassnameSpec::EnrolledInClassname'
    end

    class Lesson
      include Neo4j::ActiveNode
      property :subject
    end

    class NodeWithClassname
      include Neo4j::ActiveNode
      set_classname
    end

    class EnrolledIn
      include Neo4j::ActiveRel
      from_class ClassnameSpec::Student
      to_class ClassnameSpec::Lesson
    end

    class StudentLesson
      include Neo4j::ActiveRel
      from_class ClassnameSpec::Student
      to_class ClassnameSpec::Lesson
      type 'ENROLLED_IN_SPECIAL'
    end

    class EnrolledInClassname
      include Neo4j::ActiveRel
      from_class ClassnameSpec::Student
      to_class ClassnameSpec::Lesson
      type 'ENROLLED_IN'
      set_classname
    end
  end

  before(:all) do
    @billy    = ClassnameSpec::Student.create(name: 'Billy')
    @science  = ClassnameSpec::Lesson.create(subject: 'Science')
    @math     = ClassnameSpec::Lesson.create(subject: 'Math')
    @history  = ClassnameSpec::Lesson.create(subject: 'History')

    ClassnameSpec::EnrolledIn.create(from_node: @billy, to_node: @science)
    ClassnameSpec::StudentLesson.create(from_node: @billy, to_node: @math)
    ClassnameSpec::EnrolledInClassname.create(from_node: @billy, to_node: @history)
  end

  after(:all) do
    [ClassnameSpec::Lesson, ClassnameSpec::Student].each { |m| m.delete_all }
  end

  # these specs will fail if tested against Neo4j < 2.1.5
  describe 'neo4j 2.1.5+' do
    describe 'ActiveNode models' do
      it 'does not add _classname to nodes by default' do
        expect(@billy._persisted_obj.props).not_to have_key(:_classname)
      end

      it 'adds _classname when `set_classname` is called' do
        node = ClassnameSpec::NodeWithClassname.create
        expect(node._persisted_obj.props).to have_key(:_classname)
      end
    end

    context 'without _classname or type' do
      let(:rel) { @billy.lessons.first_rel_to(@science) }
      it 'does not add a classname property' do
        expect(rel._persisted_obj.props).not_to have_key(:_classname)
      end

      it 'is the expected type' do
        expect(rel).to be_a(ClassnameSpec::EnrolledIn)
      end
    end

    context 'without classname, with type' do
      let(:rel) { @billy.lessons_with_type.first_rel_to(@math) }

      it 'does not add a classname property' do
        expect(rel._persisted_obj.props).not_to have_key(:_classname)
      end

      require 'pry'
      it 'is the expected type' do
        expect(rel).to be_a(ClassnameSpec::StudentLesson)
      end
    end

    context 'with classname and type' do
      let(:rel) { @billy.lessons_with_classname.first_rel_to(@history) }

      it 'adds a classname property' do
        expect(rel._persisted_obj.props).to have_key(:_classname)
      end

      require 'pry'
      it 'is the expected type' do
        expect(rel).to be_a(ClassnameSpec::EnrolledInClassname)
      end
    end
  end

  describe 'neo4j 2.1.4' do
    let(:session) { Neo4j::Session.current }
    before do
      expect(session).to receive(:version).at_least(1).times.and_return('2.1.4')

      @billy    = ClassnameSpec::Student.create(name: 'Billy')
      @science  = ClassnameSpec::Lesson.create(subject: 'Science')
      @math     = ClassnameSpec::Lesson.create(subject: 'Math')
      @history  = ClassnameSpec::Lesson.create(subject: 'History')

      ClassnameSpec::EnrolledIn.create(from_node: @billy, to_node: @science)
      ClassnameSpec::StudentLesson.create(from_node: @billy, to_node: @math)
      ClassnameSpec::EnrolledInClassname.create(from_node: @billy, to_node: @history)
    end

    it 'always adds _classname and is of the expected class' do
      expect(@billy._persisted_obj.props).to have_key(:_classname)

      science_rel = @billy.lessons.first_rel_to(@science)
      expect(science_rel._persisted_obj.props).to have_key(:_classname)
      expect(science_rel).to be_a(ClassnameSpec::EnrolledIn)

      math_rel = @billy.lessons_with_type.first_rel_to(@math)
      expect(math_rel._persisted_obj.props).to have_key(:_classname)
      expect(math_rel).to be_a(ClassnameSpec::StudentLesson)

      history_rel = @billy.lessons_with_classname.first_rel_to(@history)
      expect(history_rel._persisted_obj.props).to have_key(:_classname)
      expect(history_rel).to be_a(ClassnameSpec::EnrolledInClassname)
    end
  end
end