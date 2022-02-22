require 'spec_helper'

describe ActiveGraph::Base do
  before { described_class.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r') }

  subject { described_class }

  describe '#query' do
    it 'Can make a query' do
      subject.query('MERGE path=(n)-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end

    it 'can make a query with a large payload' do
      subject.query('CREATE (n:Test) SET n = $props RETURN n', props: {text: 'a' * 10_000})
    end
  end

  describe '#queries' do
    it 'allows for multiple queries' do
      result = subject.queries do
        append 'CREATE (n:Label1) RETURN n'
        append 'CREATE (n:Label2) RETURN n'
      end

      expect(result[0].to_a[0][:n]).to be_a(Neo4j::Driver::Types::Node)
      expect(result[1].to_a[0][:n]).to be_a(Neo4j::Driver::Types::Node)
      expect(result[0].to_a[0][:n].labels.to_a).to eq([:Label1])
      expect(result[1].to_a[0][:n].labels).to eq([:Label2])
    end

    it 'allows for building with Query API' do
      result = subject.queries do
        append query.create(n: {Label1: {}}).return(:n)
      end

      expect(result[0].to_a[0][:n]).to be_a(Neo4j::Driver::Types::Node)
      expect(result[0].to_a[0][:n].labels).to eq([:Label1])
    end
  end

  describe 'transactions' do
    def create_object_by_id(id, tx)
      subject.query('CREATE (t:Temporary {id: $id})', id: id)
    end

    def get_object_by_id(id)
      first = subject.query('MATCH (t:Temporary {id: $id}) RETURN t', id: id).first
      first && first[:t]
    end

    it 'logs one query per query_set in transaction' do
      expect_queries(1) do
        subject.transaction do |tx|
          create_object_by_id(1, tx)
        end
      end
      expect(get_object_by_id(1)).to be_a(Neo4j::Driver::Types::Node)

      expect_queries(1) do
        subject.transaction do |tx|
          create_object_by_id(2, tx)
        end
      end
      expect(get_object_by_id(2)).to be_a(Neo4j::Driver::Types::Node)
    end

    it 'allows for rollback' do
      expect_queries(1) do
        subject.transaction do |tx|
          create_object_by_id(3, tx)
          tx.failure
        end
      end
      expect(get_object_by_id(3)).to be_nil

      expect_queries(1) do
        subject.transaction do |tx|
          create_object_by_id(4, tx)
          tx.failure
        end
      end
      expect(get_object_by_id(4)).to be_nil

      expect_queries(1) do
        expect do
          subject.transaction do |tx|
            create_object_by_id(5, tx)
            fail 'Failing transaction with error'
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(5)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(1) do
        subject.transaction do |_tx|
          expect do
            subject.transaction do |tx|
              create_object_by_id(6, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(6)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(2) do
        subject.transaction do |tx|
          create_object_by_id(7, tx)
          expect do
            subject.transaction do |tx|
              create_object_by_id(8, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(7)).to be_nil
      expect(get_object_by_id(8)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of outer transaction
      expect_queries(1) do
        expect do
          subject.transaction do |_tx|
            subject.transaction do |tx|
              create_object_by_id(9, tx)
              fail 'Failing transaction with error'
            end
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(9)).to be_nil
    end

    describe 'after_commit hook' do
      it 'gets called when the root transaction is closed' do
        expect(self).to receive(:callback).once
        subject.transaction do |tx1|
          subject.transaction do |tx2|
            subject.transaction do |tx3|
              tx3.after_commit(&method(:callback))
            end
          end
        end
      end

      it 'is ignored when the root transaction fails' do
        expect(self).not_to receive(:callback)
        subject.transaction do |tx1|
          subject.transaction do |tx2|
            subject.transaction do |tx3|
              tx3.after_commit(&method(:callback))
            end
          end
          tx1.failure
        end
      end

      it 'is ignored when a child transaction fails' do
        expect(self).not_to receive(:callback)
        subject.transaction do |tx1|
          subject.transaction do |tx2|
            subject.transaction do |tx3|
              tx3.after_commit(&method(:callback))
              tx3.failure
            end
          end
        end
      end
    end
  end

  describe 'results' do
    it 'handles array results' do
      hashes = subject.query("CREATE (a {b: 'c'}) RETURN [a] AS arr").map(&:to_h)

      expect(hashes).to be_a(Array)
      expect(hashes.size).to be(1)
      expect(hashes[0][:arr]).to be_a(Array)
      expect(hashes[0][:arr][0]).to be_a(Neo4j::Driver::Types::Node)
      expect(hashes[0][:arr][0].properties).to eq(b: 'c')
    end

    it 'handles map results' do
      hashes = subject.query("CREATE (a {b: 'c'}) RETURN {foo: a} AS map").map(&:to_h)

      expect(hashes).to be_a(Array)
      expect(hashes.size).to be(1)
      expect(hashes[0][:map]).to be_a(Hash)
      expect(hashes[0][:map][:foo]).to be_a(Neo4j::Driver::Types::Node)
      expect(hashes[0][:map][:foo].properties).to eq(b: 'c')
    end

    it 'handles map results with arrays' do
      hashes = subject.query("CREATE (a {b: 'c'}) RETURN {foo: [a]} AS map").map(&:to_h)

      expect(hashes).to be_a(Array)
      expect(hashes.size).to be(1)
      expect(hashes[0][:map]).to be_a(Hash)
      expect(hashes[0][:map][:foo]).to be_a(Array)
      expect(hashes[0][:map][:foo][0]).to be_a(Neo4j::Driver::Types::Node)
      expect(hashes[0][:map][:foo][0].properties).to eq(b: 'c')
    end

    it 'symbolizes keys for Neo4j objects' do
      result = subject.query('RETURN {a: 1} AS obj')

      expect(result.map(&:to_h)).to eq([{obj: {a: 1}}])

      expect(result).to be_a(Enumerable)
      expect(result.count).to be(1)
      expect(result.to_a[0][:obj]).to eq(a: 1)
    end

    describe 'parameter input and output' do
      subject { ActiveGraph::Base.query('WITH $param AS param RETURN param', param: param).first[:param] }

      [
        # Integers
        rand(10_000_000_000) * -1,
        rand(99_999_999) * -1,
        -1, 0, 1,
        rand(99_999_999),
        rand(10_000_000_000),
        # Floats
        rand * 10_000_000_000 * -1,
        rand * 99_999_999 * -1,
        -18.6288,
        -1.0, 0.0, 1.0,
        18.6288,
        rand * 99_999_999,
        rand * 10_000_000_000,
        # Strings
        '',
        'foo',
        # 'bar' * 10_000, # (16326 - 16329)    16,384 = 2^14
        'bar' * 5442,
        # Arrays
        [],
        [1, 3, 5],
        %w[foo bar],
        # Hashes / Maps
        {},
        {a: 1, b: 2},
        {a: 'foo', b: 'bar'}
      ].each do |value|
        let_context(param: value) { it { should eq(value) } }
      end

      # Asymetric values
      # Symbols
      # Commented out because Embedded doesn't deal with this well...
      # let_context(param: :foo) { it { should eq('foo') } }
      # Sets
      # Commented out because, while Bolt supports this, the default `to_json`
      # makes Sets into strings (like "#<Set:0x00007f98f21174b0>"), not arrays when serializing
      # let_context(param: Set.new([1, 2, 3])) { it { should eq([1, 2, 3]) } }
      # let_context(param: Set.new([1, 2, 3])) { it { should eq([1, 2, 3]) } }
    end

    describe 'wrapping' do
      let(:query) do
        "MERGE path=(n:Foo {a: 1})-[r:foo {b: 2}]->(b:Foo)
         RETURN #{return_clause} AS result"
      end
      subject { described_class.query(query, {}, wrap: wrap).to_a[0][:result] }

      [true, false].each do |type|
        let_context wrap: type do
          let_context return_clause: 'n' do
            it { should be_a(Neo4j::Driver::Types::Node) }
            its(:properties) { should eq(a: 1) }
          end

          let_context return_clause: 'r' do
            it { should be_a(Neo4j::Driver::Types::Relationship) }
            its(:properties) { should eq(b: 2) }
          end

          let_context return_clause: 'path' do
            it { should be_a(Neo4j::Driver::Types::Path) }
          end

          let_context(return_clause: '{c: 3}') { it { should eq(c: 3) } }
          let_context(return_clause: '[1,3,5]') { it { should eq([1, 3, 5]) } }
          let_context(return_clause: '["foo", "bar"]') { it { should eq(%w[foo bar]) } }
        end
      end

      let_context wrap: true do
        before do
          # Normally I don't think you wouldn't wrap nodes/relationships/paths
          # with the same class.  It's just expedient to do so in this spec
          stub_const 'WrapperClass', Struct.new(:wrapped_object)

          @procs = {}

          %i[Node Relationship].each do |core_class|
            klass = Neo4j::Driver::Types.const_get(core_class)
            @procs[core_class] = klass.instance_variable_get(:@wrapper_callback)
            klass.clear_wrapper_callback
            klass.wrapper_callback(WrapperClass.method(:new))
          end
        end

        after do
          %i[Node Relationship].each do |core_class|
            Neo4j::Driver::Types.const_get(core_class).instance_variable_set(:@wrapper_callback, @procs[core_class])
          end
        end

        let_context return_clause: 'n' do
          it { should be_a(WrapperClass) }
          its(:wrapped_object) { should be_a(Neo4j::Driver::Types::Node) }
          its(:'wrapped_object.properties') { should eq(a: 1) }
        end

        let_context return_clause: 'r' do
          it { should be_a(WrapperClass) }
          its(:wrapped_object) { should be_a(Neo4j::Driver::Types::Relationship) }
          its(:'wrapped_object.properties') { should eq(b: 2) }
        end

        let_context(return_clause: '{c: 3}') { it { should eq(c: 3) } }
        let_context(return_clause: '[1,3,5]') { it { should eq([1, 3, 5]) } }
        let_context(return_clause: '["foo", "bar"]') { it { should eq(%w[foo bar]) } }
      end
    end
  end

  def create_constraint(label_name, property, options = {})
    label_object = ActiveGraph::Core::Label.new(label_name)
    label_object.create_constraint(property, options)
  end

  def create_index(label_name, property, options = {})
    label_object = ActiveGraph::Core::Label.new(label_name)
    label_object.create_index(property, options)
  end

  describe 'cypher errors' do
    describe 'unique constraint error' do
      before { delete_schema }
      before { create_constraint(:Album, :uuid, type: :unique) }

      it 'raises an error' do
        described_class.query("CREATE (:Album {uuid: 'dup'})").to_a
        expect do
          described_class.query("CREATE (:Album {uuid: 'dup'})").to_a
        end.to raise_error Neo4j::Driver::Exceptions::ClientException, /already exists with label/
      end
    end

    describe 'Invalid input error' do
      it 'raises an error' do
        expect do
          described_class.query("CRATE (:Album {uuid: 'dup'})").to_a
        end.to raise_error(Neo4j::Driver::Exceptions::ClientException, /Invalid input '.*A.*'/)
      end
    end

    describe 'Clause ordering error' do
      it 'raises an error' do
        expect do
          described_class.query("RETURN 1 CREATE (a:Album {uuid: 'dup'})").to_a
        end.to raise_error Neo4j::Driver::Exceptions::ClientException, /RETURN can only be used at the end of the query/
      end
    end
  end

  describe 'schema inspection' do
    before { delete_schema }
    before do
      create_constraint(:Album, :al_id, type: :unique)
      create_constraint(:Album, :name, type: :unique)
      create_constraint(:Song, :so_id, type: :unique)

      create_index(:Band, :ba_id)
      create_index(:Band, :fisk)
      create_index(:Person, :name)
    end

    describe 'constraints' do
      let(:label) {}
      subject { described_class.constraints }

      it do
        should match_array([
                             {type: :uniqueness, label: :Album, properties: [:al_id]},
                             {type: :uniqueness, label: :Album, properties: [:name]},
                             {type: :uniqueness, label: :Song, properties: [:so_id]}
                           ])
      end
    end

    describe 'indexes' do
      let(:label) {}
      subject { ActiveGraph::Base.indexes }

      it do
        should match_array([
                             a_hash_including(label: :Band, properties: [:ba_id]),
                             a_hash_including(label: :Band, properties: [:fisk]),
                             a_hash_including(label: :Person, properties: [:name]),
                             a_hash_including(label: :Album, properties: [:al_id]),
                             a_hash_including(label: :Album, properties: [:name]),
                             a_hash_including(label: :Song, properties: [:so_id])
                           ])
      end
    end
  end
end
