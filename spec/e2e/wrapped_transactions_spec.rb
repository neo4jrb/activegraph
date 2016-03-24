describe 'wrapped nodes in transactions' do
  before(:each) do
    clear_model_memory_caches

    stub_active_node_class('Student') do
      property :name

      has_many :out, :teachers, model_class: 'Teacher', rel_class: 'StudentTeacher'
    end

    stub_active_node_class('Teacher') do
      property :name
      has_many :in, :students, model_class: 'Student', rel_class: 'StudentTeacher'
    end

    stub_active_rel_class('StudentTeacher') do
      from_class :Student
      to_class :Teacher
      type 'teacher'
      property :appreciation, type: Integer
    end
  end

  before(:each) do
    Student.delete_all
    Teacher.delete_all

    Student.create(name: 'John')
    Teacher.create(name: 'Mr Jones')
    begin
      tx = Neo4j::Transaction.new
      @john = Student.first
      @jones = Teacher.first
    ensure
      tx.close
    end
  end

  it 'can load a node within a transaction' do
    expect(@john).to be_a(Student)
    expect(@john.name).to eq 'John'
    expect(@john.id).not_to be_nil
  end

  it 'returns its :labels' do
    expect(@john.neo_id).not_to be_nil
    expect(@john.labels).to eq [Student.name.to_sym]
  end

  it 'responds positively to exist?' do
    expect(@john.exist?).to be_truthy
  end

  describe 'relationships' do
    let!(:rel) { StudentTeacher.create(from_node: @john, to_node: @jones, appreciation: 9000) }

    it 'allows the creation of rels using transaction-loaded nodes' do
      expect(rel.persisted?).to be_truthy
      expect(rel.appreciation).to eq 9000
    end

    it 'will load rels within a tranaction' do
      begin
        tx = Neo4j::Transaction.new
        retrieved_rel = @john.teachers.each_rel do |r|
          expect(r).to be_a(StudentTeacher)
        end
      ensure
        tx.close
      end
      expect(retrieved_rel.first).to be_a(StudentTeacher)
    end

    it 'does not create an additional relationship after load then save' do
      starting_count = @john.teachers.rels.count
      begin
        tx = Neo4j::Transaction.new
        @john.teachers.each_rel do |r|
          r.appreciation = 9001
          r.save
        end
      ensure
        tx.close
      end
      @john.reload
      expect(@john.teachers.rels.count).to eq starting_count
    end
  end
end
