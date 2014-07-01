require 'spec_helper'
class Student
end
class Teacher
  end

class Lesson
  include Neo4j::ActiveNode
  attribute :name

  has_n(:teachers).from(Teacher, :teaching_lessons)
  has_n(:students).from(Student, :lessons)
end

class Student
  include Neo4j::ActiveNode
  attribute :name
  attribute :age

  has_n(:lessons).to(Lesson)
end

class Teacher
  include Neo4j::ActiveNode
  attribute :name

  has_n(:teaching_lessons).to(Teacher)
end

describe 'QuickQuery Queries' do
  describe "#qq on class" do
    it 'creates a new instance of QuickQuery' do
      expect(Student.qq).to be_a(Neo4j::ActiveNode::QuickQuery)
    end

    it 'accepts a symbol to identify the first node' do
      expect(Student.qq(:foo).instance_variable_get(:@return_obj)).to eq :foo
    end

    it 'accepts a string to identify the first node' do
      expect(Student.qq('foo').instance_variable_get(:@return_obj)).to eq 'foo'
    end
  end

  describe "#qq on instance" do
    let(:chris) { Student.create(name: 'jim', age: '30') }

    it 'creates a new instance of QuickQuery' do
      expect(chris.qq).to be_a(Neo4j::ActiveNode::QuickQuery)
    end

    it 'sets the starting ID to the node ID' do
      expect(chris.qq.to_cypher).to include "= #{chris.id}"
    end
  end

  describe "#where" do

    it 'sets match parameters based on node_on_deck' do
      expect(Student.qq.where(name: 'chris').to_cypher).to include "WHERE n1.name = \"chris\""
    end

    it 'allows explicit setting of an identifier' do
      expect(Student.qq.where(:foo, name: 'chris').to_cypher).to include "WHERE foo.name = \"chris\""
    end

    it 'always increments the node identifier' do
      expect(Student.qq(:foo).lessons.instance_variable_get(:@node_on_deck)).to eq 'n2'
    end
  end

  describe "dynamic rel method creation" do
    it 'creates methods based on the calling model' do
      expect(Student.qq.respond_to?(:lessons)).to be_truthy
    end

    it 'creates new methods with each traversal to a new model' do
      expect(Student.qq.lessons.respond_to?(:teachers)).to be_truthy
    end

    it 'automatically sets a rel identifier' do
      expect(Student.qq.lessons.instance_variable_get(:@rel_on_deck)).to eq 'r1'
    end

    it 'increments the rel identifier' do
      expect(Student.qq.lessons.teachers.instance_variable_get(:@rel_on_deck)).to eq 'r2'
    end

    it 'allows explicit setting of rel identifier' do
      expect(Student.qq.lessons(rel_as: :foo).instance_variable_get(:@rel_on_deck)).to eq :foo
    end

    it 'always increments the rel identifier' do
      #we want to be sure that it increments, even if an earlier one is explicitly set
      expect(Student.qq.lessons(:foo).teachers.instance_variable_get(:@rel_on_deck)).to eq 'r2'
    end
  end

  describe "return" do
    let(:chris) { Student.create(name: 'chris', age: 30) }
    let(:history) { Lesson.create(name: 'history 101') }
    let(:math) { Lesson.create(name: 'math 101') }
    before do
      chris.lessons << history
      chris.lessons << math
      chris.save
      4.times { Student.create(age: 30) }
      6.times { Student.create(age: 31) }
    end

    it "returns an enum of the object requested" do
      expect(Student.qq.where(age: 31).return.count).to eq 6
    end

    it "returns the object requested" do
      expect(chris.qq.lessons.return(:r1).first).to be_a(Neo4j::Server::CypherRelationship)
    end
  end
end