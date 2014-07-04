require 'spec_helper'
class Student; end
class Teacher; end

class Lesson
  include Neo4j::ActiveNode
  property :name

  has_n(:teachers).from(Teacher, :teaching_lessons)
  has_n(:students).from(Student, :lessons)
end

class Student
  include Neo4j::ActiveNode
  property :name
  property :age, type: Integer
  property :occupation

  has_n(:lessons).to(Lesson)
end

class Teacher
  include Neo4j::ActiveNode
  property :name

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
    after(:all) { Student.all.each{|s| s.destroy } }
    let!(:chris) { Student.create(name: 'chris', age: 30, occupation: '') }
    let!(:lauren) { Student.create(name: 'lauren', age: 30, occupation: '') }
    let!(:jasmine) { Student.create(name: 'jasmine', age: 5, occupation: 'cat')}

    it 'sets match parameters based on node_on_deck' do
      expect(Student.qq.where(name: 'chris').to_cypher).to include "WHERE n1.name = \"chris\""
    end

    it 'allows explicit setting of an identifier' do
      expect(Student.qq.where(:foo, name: 'chris').to_cypher).to include "WHERE foo.name = \"chris\""
    end

    it 'always increments the node identifier' do
      expect(Student.qq(:foo).lessons.instance_variable_get(:@node_on_deck)).to eq 'n2'
    end

    it 'passes strings directly to core query' do
      @end = Student.qq.where('age > 29').to_a
      expect(@end).to include chris, lauren
      expect(@end).to_not include jasmine
    end

    it 'recognizes an identifier in a string' do
      expect(Student.qq(:s).where('s.age > 29').to_a).to include chris, lauren
    end

    it 'adds identifiers to strings when missing' do
      expect(Student.qq.where('age > 29').to_a).to include chris, lauren
    end
  end

  describe "#set" do
    after(:all) { Student.all.each{|s| s.destroy } }

    let!(:chris) { Student.create(name: 'chris', age: 30, occupation: '') }
    let!(:lauren) { Student.create(name: 'lauren', age: 30, occupation: '') }
    let!(:jasmine) { Student.create(name: 'jasmine', age: 5, occupation: 'cat')}
    
    it "updates the specified parameter" do
      Student.qq.set_props(occupation: 'adult').where(age: 30).return
      @nc = Student.qq.to_a.first
      expect(@nc.occupation).to eq 'adult'
    end

    it "leaves other parameters alone" do
      Student.qq.set_props(occupation: 'adult').where(age: 30).return
      expect(chris.age).to eq 30
    end

    it "updates all matching objects" do
      Student.qq.set_props(occupation: 'adult').where(age: 30).return
      expect([chris, lauren].all?{|el| el.age == 30}).to be_truthy
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
    after(:all) { Student.all.each{|s| s.destroy } }

    let!(:chris) { Student.create(name: 'chris', age: 30) }
    let!(:history) { Lesson.create(name: 'history 101') }
    let!(:math) { Lesson.create(name: 'math 101') }
    before do
      chris.lessons << history
      chris.lessons << math
      chris.save
      4.times { Student.create(age: 30) }
      6.times { Student.create(age: 31) }
    end

    it "returns an enum of the object requested" do
      expect(Student.qq.where(age: 31).return.to_a.count).to eq 6
    end

    it "returns the object requested" do
      expect(chris.qq.lessons.return(:n2).to_a.first).to be_a(Lesson)
    end

    it "uses implicit return" do
      expect(Student.qq.where(age: 30).to_a).to_not be nil
    end
  end
end