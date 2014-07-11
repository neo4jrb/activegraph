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
    after(:all) { Student.all.each{|s| s.destroy }}
    let(:chris) { Student.create(name: 'chris', age: '30') }

    it 'creates a new instance of QuickQuery' do
      expect(chris.qq).to be_a(Neo4j::ActiveNode::QuickQuery)
    end

    it 'sets the starting ID to the node ID' do
      expect(chris.qq.to_cypher).to include "= #{chris.id}"
    end
  end

  describe "filters and set" do
    after(:each) { Student.all.each{|s| s.destroy } }
    let!(:chris) { Student.create(name: 'chris', age: 30, occupation: '') }
    let!(:lauren) { Student.create(name: 'lauren', age: 31, occupation: '') }
    let!(:bob) { Student.create(name: 'bob', age: 32, occupation: '') }
    let!(:jasmine) { Student.create(name: 'jasmine', age: 5, occupation: 'cat')}
    before { @adults = [chris, lauren, bob] }

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

      it 'passes strings directly to core query' do
        result = Student.qq.where('age > 29').to_a
        expect(result).to include chris, lauren, bob
        expect(result).to_not include jasmine
      end

      it 'recognizes an identifier in a string' do
        expect(Student.qq(:s).where('s.age > 29').to_a).to include chris, lauren
      end

      it 'adds identifiers to strings when missing' do
        expect(Student.qq.where('age > 29').to_a).to include chris, lauren
      end
    end

    describe "#set_props" do      
      it "updates the specified parameter" do
        result = Student.qq.set_props(occupation: 'adult').where(age: 30).to_a
        expect(result.first.occupation).to eq 'adult'
      end

      it "does not wipe out other properties" do
        Student.qq.set_props(occupation: 'adult').where(age: 30).to_a
        expect(chris.age).to eq 30
      end

      it "updates all matching objects" do
        Student.qq.set_props(occupation: 'adult').where('age > 29').to_a
        @adults.each{|x| x.reload}
        expect(@adults.all?{|el| el.occupation == 'adult'}).to be_truthy
        expect(jasmine.occupation).to eq 'cat'
      end
    end

    describe "#set" do
      before(:each) { chris.age = 30 and chris.save }
      it "sets all unspecified properties nil" do
        Student.qq.set(occupation: 'adult').where(age: 30).to_a
        chris.reload
        expect(chris.age).to eq nil
      end

      it "updates the specified parameter" do
        result = Student.qq.set(occupation: 'adult').where(age: 30).to_a
        expect(result.first.occupation).to eq 'adult'
      end
    end   

    describe "#order" do
      it "ascends based on specified property by default" do
        result1 = Student.qq.order(:age).to_a
        result2 = Student.qq.order(:name).to_a
        expect(result1.first.name).to eq 'jasmine'
        expect(result2.first.name).to eq 'bob'
      end

      it 'descends when set true' do
        result1 = Student.qq.order(:age, true).to_a
        result2 = Student.qq.order(:name, true).to_a
        expect(result1.to_a).to eq [bob, lauren, chris, jasmine]
        expect(result2.to_a).to eq [lauren, jasmine, chris, bob]
      end
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

    describe "rel_where" do
      let!(:chris) { Student.create(name: 'chris', age: 30) }
      let!(:lauren) { Student.create(name: 'lauren', age: 31) }
      let!(:lesson) { Lesson.create(name: 'ruby 101' ) }
      after(:all) { Student.all.each{|s| s.destroy} and Lesson.all.each{|l| l.destroy } }

      it 'allows you query by relationship properties' do
        lesson.students.create(chris, grade: 'd-')
        lesson.students.create(lauren, grade: 'a+')
        result = Lesson.qq.students(rel_where: { grade: 'a+' }).to_a
        expect(result).to include lauren
        expect(result).to_not include chris
        expect(result.first).to eq lauren
      end
    end
  end

  describe "return" do
    after(:each) { Student.all.each{|s| s.destroy } }

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

    it "returns an enumerable of the object requested" do
      expect(Student.qq.where(age: 31).to_a.count).to eq 6
    end

    it "returns the object requested" do
      expect(chris.qq.lessons.return(:n2).to_a.first).to be_a(Lesson)
    end

    it "uses implicit return" do
      expect(Student.qq.where(age: 30).to_a).to_not be nil
    end
  end

  describe "to_a and to_a!" do
    after(:each) { Student.all.each{|s| s.destroy} and Lesson.all.each{|l| l.destroy } }
    let!(:history) { Lesson.create(name: 'history 101') } 
    before { ['s1', 's2', 's3', 's4'].each{ |s| Student.create(name: s).lessons << history } }

    describe 'to_a' do
      it 'returns the on_deck node' do
        expect(Student.qq.lessons.to_a.first).to eq history
      end

      it 'can return multiple instances of the same object' do
        expect(Student.qq.lessons.to_a.count).to eq 4
      end
    end

    describe 'to_a!' do
      it 'returns the on deck node' do
        expect(Student.qq.lessons.to_a!.first).to eq history
      end
      
      it 'returns a distinct result' do
        expect(Student.qq.lessons.to_a!.count).to eq 1
      end
    end
  end
end
