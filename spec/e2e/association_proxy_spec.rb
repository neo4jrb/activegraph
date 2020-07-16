describe 'Association Proxy' do
  before do
    clear_model_memory_caches
  end

  context 'simple relationships' do
    before do
      stub_node_class('Student') do
        property :name
        has_many :out, :lessons, rel_class: :LessonEnrollment
        has_many :in, :exams, model_class: :Exam, origin: :students
        has_one :out, :favorite_lesson, type: nil, model_class: :Lesson
        has_many :out, :homework, type: :HOMEWORK, model_class: %w[Lesson Exam]
        has_many :out, :friends, type: :friend, model_class: :Student
      end

      stub_relationship_class('LessonEnrollment') do
        from_class :Student
        to_class :Lesson
        type :has_studet

        property :grade
      end

      stub_node_class('Lesson') do
        property :subject
        property :level, type: Integer
        has_many :in, :students, model_class: :Student, origin: :lessons
        has_many :out, :exams_given, type: nil, model_class: :Exam
      end

      stub_node_class('Exam') do
        property :name
        has_many :in, :lessons, model_class: :Lesson, origin: :exams_given
        has_many :out, :students, type: :has_student, model_class: :Student
      end
    end

    let(:billy) { Student.create(name: 'Billy') }
    let(:math) { Lesson.create(subject: 'math', level: 101) }
    let(:science) { Lesson.create(subject: 'science', level: 102) }
    let(:math_exam) { Exam.create(name: 'Math Exam') }
    let(:science_exam) { Exam.create(name: 'Science Exam') }
    let(:science_exam2) { Exam.create(name: 'Science Exam 2') }
    let(:leszek) { Student.create(name: 'Leszek', friends: [zinto]) }
    let(:zinto) { Student.create(name: 'Zinto') }

    before do
      [math, science].each { |lesson| billy.lessons << lesson }
      [math_exam, science_exam].each { |exam| billy.exams << exam }
      math.exams_given << math_exam
      science.exams_given << science_exam
      science.exams_given << science_exam2
      billy.favorite_lesson = math
    end

    context 'self referencing relationships' do
      before { leszek }
      it 'fire only one query' do
        expect_queries(1) do
          Student.all.order(:name).with_associations(:friends).each do |student|
            student.friends.to_a
          end
        end
      end
    end

    it 'allows associations to respond to to_ary' do
      expect(billy.lessons).to respond_to(:to_ary)
      expect(billy.lessons.exams_given).to respond_to(:to_ary)
    end

    it 'does not recreate relatioship for existing relationships' do
      rel_id = science.exams_given.where(id: science_exam.id).rel.id
      science.exams_given = [science_exam]
      expect(Lesson.find(science.id).exams_given.rel.id).to eq(rel_id)
      science.exams_given_ids = [science_exam.id]
      expect(Lesson.find(science.id).exams_given.rel.id).to eq(rel_id)
    end

    it 'Should only make one query per association' do
      expect(billy.lessons.exams_given).to match_array([math_exam, science_exam, science_exam2])

      expect_queries(3) do
        grouped_lessons = billy.lessons.group_by(&:subject)

        expect(billy.lessons).to match_array([math, science])
        expect(grouped_lessons['math'][0].exams_given).to eq([math_exam])
        expect(grouped_lessons['science'][0].exams_given).to match_array([science_exam, science_exam2])

        expect(grouped_lessons['math'][0].students).to eq([billy])
        expect(grouped_lessons['science'][0].students).to eq([billy])
      end
    end

    it 'Should only make one query association from a model query' do
      expect_queries(3) do
        grouped_exams = Exam.all.group_by(&:name)

        expect(grouped_exams['Science Exam'][0].students).to eq([billy])
        expect(grouped_exams['Science Exam'][0].lessons).to eq([science])

        expect(grouped_exams['Math Exam'][0].students).to eq([billy])
        expect(grouped_exams['Math Exam'][0].lessons).to eq([math])
      end
    end

    it 'Should allow for loading of associations with one query' do
      expect_queries(1) do
        grouped_lessons = billy.lessons.with_associations(:exams_given, :students).group_by(&:subject)

        expect(grouped_lessons['math'][0].students).to eq([billy])
        expect(grouped_lessons['math'][0].exams_given).to eq([math_exam])

        expect(grouped_lessons['science'][0].students).to eq([billy])
        expect(grouped_lessons['science'][0].exams_given).to match_array([science_exam, science_exam2])
      end
    end

    it 'Should allow for loading of associations with one query on multiple to_a calls' do
      expect_queries(1) do
        query = billy.lessons.with_associations(:exams_given, :students)
        query.to_a
        query.to_a
      end
    end

    it 'Should allow for loading of associations with one query when method chain ends with first' do
      expect_queries(1) do
        billy.lessons.with_associations(:exams_given).first.exams_given.to_a
      end
    end

    it 'Should allow for loading of associations with one query when method chain ends with branch' do
      expect_queries(1) do
        billy.as(:b).with_associations(:lessons).branch { lessons }.first.lessons.to_a
      end
    end

    it 'Should allow for loading of `has_one` association' do
      expect_queries(1) do
        grouped_students = science.students.with_associations(:favorite_lesson).group_by(&:name)

        expect(grouped_students['Billy'][0].favorite_lesson).to eq(math)

        expect(grouped_students.size).to eq(1)
        expect(grouped_students['Billy'].size).to eq(1)
      end
    end

    it 'Queries limited times in depth two loops with with_associations' do
      Student.create.lessons << science
      Student.create.lessons << science
      expect_queries(4) do
        science.students.with_associations(:lessons).each do |student|
          student.lessons.with_associations(:exams_given).each do |lesson|
            lesson.exams_given.to_a
          end
        end
      end
    end

    it 'Queries limited times in depth two loops with deep with_associations' do
      Student.create.lessons << science
      Student.create.lessons << science
      expect_queries(1) do
        science.students.with_associations(lessons: :exams_given).each do |student|
          student.lessons.each do |lesson|
            lesson.exams_given.to_a
          end
        end
      end
    end

    it 'Queries limited times in depth two loops with deep with_associations iterating over relationships' do
      Student.create.lessons << science
      Student.create.lessons << science
      expect_queries(1) do
        science.students.with_associations(lessons: :exams_given).each do |student|
          student.lessons.rels.each do |lesson_rel|
            lesson_rel.end_node.exams_given.to_a
          end
        end
      end
    end

    it 'Queries limited times in depth two loops with deep with_associations iterating over relationships with each_rel' do
      Student.create.lessons << science
      Student.create.lessons << science
      expect_queries(1) do
        science.students.with_associations(lessons: :exams_given).each do |student|
          student.lessons.each_rel do |lesson_rel|
            lesson_rel.end_node.exams_given.to_a
          end
        end
      end
    end

    it 'does not fetches duplicate nodes with deep with_associations' do
      Student.create(name: 'Leszek').lessons << science
      Student.create(name: 'Lukasz').lessons << science
      Student.all.with_associations(lessons: :exams_given).each do |student|
        student.lessons.each do |lesson|
          expect(lesson.exams_given).to contain_exactly(science_exam, science_exam2) if lesson == science
        end
      end
    end

    it 'Queries only one time when there are some empty associations' do
      Student.create.lessons << science
      Student.create.lessons += [science, Lesson.create]
      expect_queries(1) do
        science.students.with_associations(lessons: :exams_given).flat_map(&:lessons).flat_map(&:exams_given)
      end
    end

    it 'Raises error if attempting to deep eager load "past" a polymorphic association' do
      expect { math.students.with_associations(homework: :lessons) }.to raise_error(RuntimeError, /Cannot eager load "past" a polymorphic association/)
    end

    it 'Queries limited times in depth two loops' do
      Student.create.lessons << science
      Student.create.lessons << science
      expect_queries(5) do
        science.students.each do |student|
          student.lessons.each do |lesson|
            lesson.exams_given.to_a
          end
        end
      end
    end

    it 'does not make extra queries when using .create' do
      lesson = Lesson.create
      expect_queries(2) do
        science.students.each do |student|
          student.lessons.create(lesson)
        end
      end
    end

    describe 'support relationship type as label' do
      before do
        stub_node_class('Roster') do
          has_many :out, :students, type: :student
        end
      end

      it 'Queries only 1 time' do
        Roster.create(students: [billy])
        expect_queries(1) do
          Roster.all.with_associations(:students).each do |roster|
            roster.students.to_a
          end
        end
      end
    end

    describe 'ordering' do
      it 'supports before with_association' do
        expect(Lesson.order(:subject).with_associations(:students).map(&:subject)).to eq(%w(math science))
        expect(Lesson.order(subject: :desc).with_associations(:students).map(&:subject)).to eq(%w(science math))
      end

      it 'supports after with_association' do
        expect(Lesson.all.with_associations(:students).order(:subject).map(&:subject)).to eq(%w(math science))
        expect(Lesson.all.with_associations(:students).order(subject: :desc).map(&:subject)).to eq(%w(science math))
      end
    end

    describe 'ordering with limit' do
      it 'supports ordering with limit and with_associations' do
        expect(Lesson.order(:subject).limit(1).with_associations(:students).map(&:subject)).to eq(%w(math))
        expect(Lesson.order(subject: :desc).limit(1).with_associations(:students).map(&:subject)).to eq(%w(science))
      end
    end

    describe 'issue reported by @andrewhavens in #881' do
      it 'does not break' do
        l1 = Lesson.create!.tap { |l| l.exams_given = [Exam.create!] }
        l2 = Lesson.create!.tap { |l| l.exams_given = [Exam.create!, Exam.create!] }
        student = Student.create!.tap { |s| s.lessons = [l1, l2] }
        totals = {l1.id => l1.exams_given.count, l2.id => l2.exams_given.count}

        student.lessons.each do |l|
          expect(totals[l.id]).to eq l.exams_given.count
        end
      end
    end

    describe 'target' do
      context 'when none found' do
        it 'raises an error' do
          expect { billy.lessons.foo }.to raise_error NoMethodError
        end
      end
    end

    context 'when requiring "active_support/core_ext/enumerable"' do
      require 'active_support/core_ext/enumerable'

      it 'uses the correct `pluck` method' do
        expect(billy.lessons(:l).pluck(:l)).not_to include(nil)
        expect(billy.lessons(:l).method(:pluck).source_location.first).not_to include('active_support')
      end
    end

    describe '#inspect' do
      context 'when inspecting an association proxy' do
        let(:association_proxy) { billy.lessons }
        let(:inspected_elements) { association_proxy.inspect }

        it 'returns the list of resulting elements' do
          expect(inspected_elements).to include('#<AssociationProxy Student#lessons')
          expect(inspected_elements).to include(association_proxy.to_a.inspect)
        end
      end
    end
  end

  context 'multi relationships' do
    before do
      stub_node_class('Person') do
        property :name

        has_many :out, :knows, model_class: 'Person', type: nil
        has_many :in, :posts, type: :posts
        has_many :in, :comments, type: :comments
        has_one :out, :parent, type: :parent, model_class: 'Person', dependent: :delete
        has_many :in, :children, origin: :parent, model_class: 'Person'
        has_many :out, :owner_comments, type: :comments, model_class: 'Comment'
      end

      stub_node_class('Post') do
        property :name

        has_one :out, :owner, origin: :posts, model_class: 'Person'
        has_many :in, :comments, type: :posts
      end

      stub_node_class('Comment') do
        property :text

        has_one :out, :owner, origin: :comments, model_class: 'Person'
        has_one :in, :comment_owner, origin: :owner_comments, model_class: 'Person'
        has_one :out, :post, origin: :comments, model_class: 'Post'
      end
    end

    def deep_traversal(person)
      person.knows.each(&method(:deep_traversal))
    end

    context 'variable lenght relationship with with_associations' do
      let(:node) { Person.create(name: 'Billy', knows: friend1) }
      let(:friend1) { Person.create(name: 'f-1', knows: friend2) }
      let(:friend2) { Person.create(name: 'f-2', knows: friend3) }
      let(:friend3) { Person.create(name: 'f-3') }
      let(:billy_comment) { Comment.create(text: 'test-comment', owner: node) }
      let(:comment) { Comment.create(text: 'test-comment', owner: friend1) }

      before { Post.create(name: 'Post-1', owner: node, comments: [comment, billy_comment]) }

      it 'Should allow for string parameter with variable length relationship notation' do
        expect_queries(1) do
          Post.comments.with_associations(owner: 'knows*').map(&:owner).each(&method(:deep_traversal))
        end
      end


      it 'allows on demand retrieval beyond eagerly fetched associations' do
        expect(Post.owner.with_associations('knows*2')[0].knows[0].knows[0].knows[0].name).to eq 'f-3'
      end

      it 'Should allow for string parameter with fixed length relationship notation' do
        expect(queries_count do
          owners = Post.comments.with_associations('owner.knows*2').map(&:owner)
          owners.each(&method(:deep_traversal))
        end).to be > 1
      end

      it '* does not supress other relationships at the same level' do
        expect_queries(2) do
          expect(Post.owner(chainable: true).with_associations('knows*.comments').first.comments).to_not be_empty
        end
      end

      it 'Should allow for string parameter with variable length relationship notation' do
        expect_queries(1) do
          Post.owner(chainable: true).with_associations('knows*.comments').each do |owner|
            owner.knows.each do |known|
              known.knows[0].comments.to_a
            end
          end
        end
      end
    end

    context 'eager fetching of leafs' do
      it 'marks missing * relationships as empty on the initial query' do
        Person.create
        expect_queries(1) do
          Person.all.with_associations('knows*').each(&method(:deep_traversal))
        end
      end

      it 'marks missing * relationships as empty at the leaf' do
        pending 'for simplicity of implementation leafs at depth < max_depth are not initialized'
        person = Person.create(knows: Person.create)
        expect_queries(1) do
          person.as(:p).with_associations('knows*2').each(&method(:deep_traversal))
        end
      end
    end

    it 'deletes inverse has_one rel and does not call callbacks in inverse rel' do
      person3 = Person.create(name: '3')
      person2 = Person.create(name: '2', children: [person3])
      person1 = Person.create(name: '1', children: [person2])
      person1.update(children: [person2, person3.id])

      expect(person3.as(:p).parent.count).to eq(1)
      expect { Person.find(person2.id) }.not_to raise_error
    end

    it 'deletes rel in case of inverse has_one rel and two relationships with same type' do
      person1 = Person.create(name: 'person-1')
      person2 = Person.create(name: 'person-2')
      comment = Comment.create(text: 'test-comment-2', comment_owner: person1)
      person2.owner_comments = [comment]
      expect(comment.as(:c).comment_owner.count).to eq(1)
    end
  end
end
