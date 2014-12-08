require 'spec_helper'

describe 'query_proxy_methods' do
  # goofy names to differentiate from same classes used elsewhere
  before(:all) do
    class IncludeLesson; end
    class IncludeTeacher; end
    class IncludeEmptyClass; end
    class IncludeEnrolledIn; end
    class IncludeStudent
      include Neo4j::ActiveNode
      property :name
      has_many :out, :lessons, model_class: IncludeLesson, rel_class: IncludeEnrolledIn
      has_many :out, :things, model_class: false, type: 'lessons'
    end

    class IncludeLesson
      include Neo4j::ActiveNode
      property :name
      has_many :in, :students, model_class: IncludeStudent, rel_class: IncludeEnrolledIn
      has_many :in, :teachers, model_class: IncludeTeacher, origin: :lessons
    end

    class IncludeTeacher
      include Neo4j::ActiveNode
      property :name
      property :age, type: Integer
      has_many :out, :lessons, model_class: IncludeLesson, type: 'teaching_lesson'
    end

    class IncludeEmptyClass
      include Neo4j::ActiveNode
      has_many :out, :lessons, model_class: IncludeLesson
    end

    class IncludeEnrolledIn
      include Neo4j::ActiveRel
      from_class IncludeStudent
      to_class IncludeLesson
      type 'lessons'
    end
  end
  let!(:jimmy)    { IncludeStudent.create(name: 'Jimmy') }
  let!(:math)     { IncludeLesson.create(name: 'math') }
  let!(:science)  { IncludeLesson.create(name: 'science') }
  let!(:mr_jones) { IncludeTeacher.create }
  let!(:mr_adams) { IncludeTeacher.create }

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
      expect(IncludeTeacher.all.include?(mr_jones)).to be_truthy
      expect(IncludeTeacher.all.include?(math)).to be_falsey
    end

    it 'works with multiple relationships to the same object' do
      jimmy.lessons << science
      jimmy.lessons << science
      expect(jimmy.lessons.include?(science)).to be_truthy
    end

    it 'returns correctly when model_class is false' do
      woodworking = IncludeLesson.create(name: 'woodworking')
      expect(jimmy.things.include?(woodworking)).to be_falsey
      jimmy.lessons << woodworking
      expect(jimmy.things.include?(woodworking)).to be_truthy
      woodworking.destroy
    end

    it 'allows you to check for an identifier in the middle of a chain' do
      jimmy.lessons << science
      science.teachers << mr_adams
      expect(IncludeLesson.as(:l).students.where(name: 'Jimmy').include?(science, :l)).to be_truthy
    end

    it 'raises an error if something other than a node is given' do
      expect { IncludeStudent.lessons.include?(:foo) }.to raise_error(Neo4j::ActiveNode::Query::QueryProxyMethods::InvalidParameterError)
    end
  end

  describe 'exists?' do
    context 'class methods' do
      it 'can run by a class' do
        expect(IncludeEmptyClass.empty?).to be_truthy
        expect(IncludeLesson.empty?).to be_falsey
      end

      it 'can be called with a property and value' do
        expect(IncludeLesson.exists?(name: 'math')).to be_truthy
        expect(IncludeLesson.exists?(name: 'boat repair')).to be_falsey
      end

      it 'can be called on the class with a neo_id' do
        expect(IncludeLesson.exists?(math.neo_id)).to be_truthy
        expect(IncludeLesson.exists?(8675309)).to be_falsey
      end

      it 'raises an error if something other than a neo id is given' do
        expect { IncludeLesson.exists?(:fooooo) }.to raise_error(Neo4j::ActiveNode::QueryMethods::InvalidParameterError)
      end
    end

    context 'QueryProxy methods' do
      it 'can be called on a query' do
        expect(IncludeLesson.where(name: 'history').exists?).to be_falsey
        expect(IncludeLesson.where(name: 'math').exists?).to be_truthy
      end

      it 'can be called with property and value' do
        expect(jimmy.lessons.exists?(name: 'science')).to be_falsey
        jimmy.lessons << science
        expect(jimmy.lessons.exists?(name: 'science')).to be_truthy
        expect(jimmy.lessons.exists?(name: 'bomb disarming')).to be_falsey
      end

      it 'can be called with a neo_id' do
        expect(IncludeLesson.where(name: 'math').exists?(math.neo_id)).to be_truthy
        expect(IncludeLesson.where(name: 'math').exists?(science.neo_id)).to be_falsey
      end

      it 'is called by :blank? and :empty?' do
        expect(jimmy.lessons.blank?).to be_truthy
        expect(jimmy.lessons.empty?).to be_truthy
        jimmy.lessons << science
        expect(jimmy.lessons.blank?).to be_falsey
        expect(jimmy.lessons.empty?).to be_falsey
      end
    end
  end

  describe 'count' do
    before(:all) do
      @john = IncludeStudent.create(name: 'Paul')
      @history = IncludeLesson.create(name: 'history')
      3.times { @john.lessons << @history }
    end

    it 'tells you the number of matching objects' do
      expect(@john.lessons.count).to eq(3)
    end

    it 'can tell you the number of distinct matching objects' do
      expect(@john.lessons.count(:distinct)).to eq 1
    end

    it 'raises an exception if a bad parameter is passed' do
      expect { @john.lessons.count(:foo) }.to raise_error(Neo4j::ActiveNode::Query::QueryProxyMethods::InvalidParameterError)
    end

    it 'works on an object earlier in the chain' do
      expect(IncludeStudent.as(:s).lessons.where(name: 'history').count(:distinct, :s)).to eq 1
    end

    it 'works with order clause' do
      expect{ IncludeStudent.order(name: :asc).count }.not_to raise_error
    end

    it 'is aliased by length and size' do
      expect(@john.lessons.size).to eq(3)
      expect(@john.lessons.length).to eq(3)
    end
  end

  describe 'delete_all' do
    before do
      IncludeStudent.destroy_all
      IncludeLesson.destroy_all
      IncludeTeacher.destroy_all
      @tom = IncludeStudent.create(name: 'Tom')
      @math = IncludeLesson.create(name: 'Math')
      @science = IncludeLesson.create(name: 'Science')
      @adams = IncludeTeacher.create(name: 'Mr Adams')
      @johnson = IncludeTeacher.create(name: 'Mrs Johnson')
      @tom.lessons << @math
      @tom.lessons << @science
      @math.teachers << @adams
      @science.teachers << @johnson
    end

    it 'removes the last link in the QueryProxy chain' do
      expect(@tom.lessons.teachers.include?(@adams)).to be_truthy
      @tom.lessons.teachers.delete_all
      expect(@adams.persisted?).to be_falsey
      expect(@johnson.persisted?).to be_falsey
      expect(@tom.lessons.teachers).to be_empty
    end

    it 'does not touch earlier portions of the chain' do
      expect(@tom.lessons.include?(@math)).to be_truthy
      @tom.lessons.teachers.delete_all
      expect(@math.persisted?).to be_truthy
    end

    it 'works when called from a class' do
      expect(@tom.lessons.teachers.include?(@adams)).to be_truthy
      IncludeStudent.all.lessons.teachers.delete_all
      expect(@adams.persisted?).to be_falsey
    end

    it 'can target a specific identifier' do
      @tom.lessons(:l).teachers.where(name: 'Mr Adams').delete_all(:l)
      expect(@tom.lessons.include?(@math)).to be_falsey
      expect(@math).not_to be_persisted
      expect(@tom.lessons.include?(@science)).to be_truthy
    end

    it 'can target relationships' do
      @tom.lessons(:l, :r).teachers.where(name: 'Mr Adams').delete_all(:r)
      expect(@tom.lessons.include?(@math)).to be_falsey
      expect(@math).to be_persisted
    end
  end

  describe 'match_to and first_rel_to' do
    before(:all) do
      @john = IncludeStudent.create(name: 'Paul')
      @history = IncludeLesson.create(name: 'history')
      @math = IncludeLesson.create(name: 'math')
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
          expect(@john.lessons.match_to(@history).to_cypher).to include('AND ID(result) =')
        end

        it 'matches the object' do
          expect(@john.lessons.match_to(@history).limit(1).first).to eq @history
        end
      end

      context 'with an id' do
        it 'generates cypher using the primary key' do
          expect(@john.lessons.match_to(@history.id).to_cypher).to include('AND result.uuid =')
        end

        it 'matches' do
          expect(@john.lessons.match_to(@history.id).limit(1).first).to eq @history
        end
      end

      context 'with an array' do
        context 'of nodes' do
          after { @john.lessons.first_rel_to(@math).destroy }

          it 'generates cypher using IN with the IDs of contained nodes' do
            expect(@john.lessons.match_to([@history, @math]).to_cypher).to include ('AND result.uuid IN')
            expect(@john.lessons.match_to([@history, @math]).to_a).to eq [@history]
            @john.lessons << @math
            expect(@john.lessons.match_to([@history, @math]).to_a.count).to eq 2
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
          expect(@john.lessons.match_to(nil).to_cypher).to include('AND 1 = 2')
        end

        it 'matches nil' do
          expect(@john.lessons.match_to(nil).first).to be_nil
        end
      end

      context 'on Model.all' do
        it 'works with a node' do
          expect(IncludeLesson.all.match_to(@history).first).to eq @history
        end

        it 'works with an id' do
          expect(IncludeLesson.all.match_to(@history.id).first).to eq @history
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
          expect(IncludeStudent.all.match_to(jimmy).lessons(:l).match_to(math).teachers.where(age: 40).first).to eq mr_jones
        end
      end
    end

    describe 'first_rel_to' do
      it 'returns the first relationship across a QueryProxy chain to a given node' do
        expect(@john.lessons.first_rel_to(@history)).to be_a IncludeEnrolledIn
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
        @john.clear_association_cache
        expect(@john.lessons.all_rels_to(@history)).to be_empty
      end
    end

  end
end
