require 'spec_helper'

describe "has_one" do

  describe 'has_one(:parent).from(:children)' do
    class HasOneA
      include Neo4j::ActiveNode
      property :name
      has_n :children
    end

    class HasOneB
      include Neo4j::ActiveNode
      property :name
      has_one(:parent).from(:children)
    end

    it 'find the nodes via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      c = HasOneB.create(name: 'c')
      a.children << b
      a.children << c

      c.parent.should == a
      b.parent.should == a
      a.children.should =~ [b,c]
    end

    it 'can create a relationship via the has_one accessor' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      b.parent.should == a
      a.children.to_a.should == [b]
    end

    it 'can return relationship object via parent_rel' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      rel = b.parent_rel
      rel.other_node(b).should == a
    end

    it 'deletes previous parent relationship' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      a.children << b
      a.children.to_a.should eq([b])
      b.parent.should eq(a)

      a2 = HasOneA.create(name: 'a2')
      # now it should delete this relationship created above
      b.parent = a2

      b.parent.should eq(a2)
      a2.children.to_a.should eq([b])
    end

    it 'can access relationship via #nodes method' do
      a = HasOneA.create(name: 'a')
      b = HasOneB.create(name: 'b')
      b.parent = a
      b.nodes(dir: :incoming, type: HasOneB.parent).to_a.should == [a]
      a.nodes(dir: :outgoing, type: HasOneB.parent).to_a.should == [b]
    end
  end

  describe 'has_one(:parent).from(Folder.files)' do
    class Folder1
      include Neo4j::ActiveNode
    end

    class File1
      include Neo4j::ActiveNode
    end

    Folder1.has_n(:files).to(File1)
    File1.has_one(:parent).from(Folder1.files)

    it 'can access nodes via parent has_one relationship' do
      f1 = Folder1.create
      file1 = File1.create
      file2 = File1.create
      f1.files << file1 << file2
      f1.files.should =~ [file1, file2]
      file1.parent.should == f1
      file2.parent.should == f1
    end
  end

  describe 'callbacks' do
    class Student; end

    class Teacher
      include Neo4j::ActiveNode

      property :student_number, type: Integer

      has_one(:student_before, before: :before_callback).to(Student)
      has_one(:student_after, after: :after_callback).to(Student)

      private

      def before_callback(from, to)
        return false if to.age == 20

      end

      def after_callback(from, to)
        return false if from.student_number == 50
        from.student_number = 1
        from.save
      end
    end

    class Student
      include Neo4j::ActiveNode

      property :age
    end

    let(:teacher) { Teacher.create }
    let(:student) { Student.create }

    describe 'before' do
      context 'failing' do
        before(:each) { student.age = 20 and student.save }

        it 'prevents a relationship from being created if response is explicitly false' do
          teacher.student_before = student
          expect(teacher.student_before).to eq nil
        end
      end

      context 'passing' do
        before(:each) { student.age = 21 and student.save }
        
        it 'creates the relationship when callback response is not explicitly false' do 
          teacher.student_before = student
          expect(teacher.student_before).to eq student
        end
      end
    end

    describe 'after' do
      it 'runs the after callback function' do
        teacher.student_number = 0 and teacher.save
        teacher.student_after = student
        expect(teacher.student_number).to eq 1
      end
    end
  end


end