# Requires that an `adaptor` let variable exist with the adaptor
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adaptor' do
  let(:real_session) do
    Neo4j::Core::CypherSession.new(adaptor)
  end
  let(:session_double) { double('session', adaptor: adaptor) }

  before { adaptor.query(session_double, 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r') }

  subject { adaptor }

  describe '#query' do
    it 'Can make a query' do
      adaptor.query(session_double, 'MERGE path=(n)-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end

    it 'can make a query with a large payload' do
      adaptor.query(session_double, 'CREATE (n:Test) SET n = {props} RETURN n', props: {text: 'a' * 10_000})
    end
  end

  describe '#queries' do
    it 'allows for multiple queries' do
      result = adaptor.queries(session_double) do
        append 'CREATE (n:Label1) RETURN n'
        append 'CREATE (n:Label2) RETURN n'
      end

      expect(result[0].to_a[0].n).to be_a(Neo4j::Driver::Types::Node)
      expect(result[1].to_a[0].n).to be_a(Neo4j::Driver::Types::Node)
      if adaptor.supports_metadata?
        expect(result[0].to_a[0].n.labels.to_a).to eq([:Label1])
        expect(result[1].to_a[0].n.labels).to eq([:Label2])
      else
        expect(result[0].to_a[0].n.labels).to eq(nil)
        expect(result[1].to_a[0].n.labels).to eq(nil)
      end
    end

    it 'allows for building with Query API' do
      result = adaptor.queries(session_double) do
        append query.create(n: {Label1: {}}).return(:n)
      end

      expect(result[0].to_a[0].n).to be_a(Neo4j::Driver::Types::Node)
      expect(result[0].to_a[0].n.labels).to eq(adaptor.supports_metadata? ? [:Label1] : nil)
    end
  end

  describe 'transactions' do
    def create_object_by_id(id, tx)
      tx.query('CREATE (t:Temporary {id: {id}})', id: id)
    end

    def get_object_by_id(id, adaptor)
      first = adaptor.query(session_double, 'MATCH (t:Temporary {id: {id}}) RETURN t', id: id).first
      first && first.t
    end

    it 'logs one query per query_set in transaction' do
      expect_queries(1) do
        tx = adaptor.transaction(session_double)
        create_object_by_id(1, tx)
        tx.close
      end
      expect(get_object_by_id(1, adaptor)).to be_a(Neo4j::Driver::Types::Node)

      expect_queries(1) do
        adaptor.transaction(session_double) do |tx|
          create_object_by_id(2, tx)
        end
      end
      expect(get_object_by_id(2, adaptor)).to be_a(Neo4j::Driver::Types::Node)
    end

    it 'allows for rollback' do
      expect_queries(1) do
        tx = adaptor.transaction(session_double)
        create_object_by_id(3, tx)
        tx.mark_failed
        tx.close
      end
      expect(get_object_by_id(3, adaptor)).to be_nil

      expect_queries(1) do
        adaptor.transaction(session_double) do |tx|
          create_object_by_id(4, tx)
          tx.mark_failed
        end
      end
      expect(get_object_by_id(4, adaptor)).to be_nil

      expect_queries(1) do
        expect do
          adaptor.transaction(session_double) do |tx|
            create_object_by_id(5, tx)
            fail 'Failing transaction with error'
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(5, adaptor)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(1) do
        adaptor.transaction(session_double) do |_tx|
          expect do
            adaptor.transaction(session_double) do |tx|
              create_object_by_id(6, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(6, adaptor)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(2) do
        adaptor.transaction(session_double) do |tx|
          create_object_by_id(7, tx)
          expect do
            adaptor.transaction(session_double) do |tx|
              create_object_by_id(8, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(7, adaptor)).to be_nil
      expect(get_object_by_id(8, adaptor)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of outer transaction
      expect_queries(1) do
        expect do
          adaptor.transaction(session_double) do |_tx|
            adaptor.transaction(session_double) do |tx|
              create_object_by_id(9, tx)
              fail 'Failing transaction with error'
            end
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(9, adaptor)).to be_nil
    end

    describe 'after_commit hook' do
      it 'gets called when the root transaction is closed' do
        data = false
        tx1 = adaptor.transaction(session_double)
        tx2 = adaptor.transaction(session_double)
        tx3 = adaptor.transaction(session_double)
        tx3.root.after_commit { data = true }
        tx3.close
        tx2.close
        expect { tx1.close }.to change { data }.to(true)
        expect(data).to be_truthy
      end

      it 'is ignored when the root transaction fails' do
        data = false
        tx1 = adaptor.transaction(session_double)
        tx2 = adaptor.transaction(session_double)
        tx3 = adaptor.transaction(session_double)
        tx3.root.after_commit { data = true }
        tx1.mark_failed
        tx3.close
        tx2.close
        expect { tx1.close }.not_to change { data }
        expect(data).to be_falsey
      end

      it 'is ignored when a child transaction fails' do
        data = false
        tx1 = adaptor.transaction(session_double)
        tx2 = adaptor.transaction(session_double)
        tx3 = adaptor.transaction(session_double)
        tx3.root.after_commit { data = true }
        tx3.mark_failed
        tx3.close
        tx2.close
        expect { tx1.close }.not_to change { data }
        expect(data).to be_falsey
      end
    end
    # it 'does not allow transactions in the wrong order' do
    #   expect { adaptor.end_transaction }.to raise_error(RuntimeError, /Cannot close transaction without starting one/)
  end

  describe 'results' do
    it 'handles array results' do
      result = adaptor.query(session_double, "CREATE (a {b: 'c'}) RETURN [a] AS arr")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:arr]).to be_a(Array)
      expect(result.hashes[0][:arr][0]).to be_a(Neo4j::Driver::Types::Node)
      expect(result.hashes[0][:arr][0].properties).to eq(b: 'c')
    end

    it 'handles map results' do
      result = adaptor.query(session_double, "CREATE (a {b: 'c'}) RETURN {foo: a} AS map")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:map]).to be_a(Hash)
      expect(result.hashes[0][:map][:foo]).to be_a(Neo4j::Driver::Types::Node)
      expect(result.hashes[0][:map][:foo].properties).to eq(b: 'c')
    end

    it 'handles map results with arrays' do
      result = adaptor.query(session_double, "CREATE (a {b: 'c'}) RETURN {foo: [a]} AS map")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:map]).to be_a(Hash)
      expect(result.hashes[0][:map][:foo]).to be_a(Array)
      expect(result.hashes[0][:map][:foo][0]).to be_a(Neo4j::Driver::Types::Node)
      expect(result.hashes[0][:map][:foo][0].properties).to eq(b: 'c')
    end

    it 'symbolizes keys for Neo4j objects' do
      result = adaptor.query(session_double, 'RETURN {a: 1} AS obj')

      expect(result.hashes).to eq([{obj: {a: 1}}])

      structs = result.structs
      expect(structs).to be_a(Array)
      expect(structs.size).to be(1)
      expect(structs[0].obj).to eq(a: 1)
    end

    describe 'parameter input and output' do
      subject { adaptor.query(session_double, 'WITH {param} AS param RETURN param', param: param).first.param }

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
      subject { adaptor.query(session_double, query, {}, wrap_level: wrap_level).to_a[0].result }

      # `wrap_level: nil` should resolve to `wrap_level: :core_entity`
      [nil, :core_entity].each do |type|
        let_context wrap_level: type do
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

      let_context wrap_level: :proc do
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

  def create_constraint(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_constraint(property, options)
  end

  def create_index(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_index(property, options)
  end

  describe 'cypher errors' do
    describe 'unique constraint error' do
      before { delete_schema(real_session) }
      before { create_constraint(real_session, :Album, :uuid, type: :unique) }

      it 'raises an error' do
        adaptor.query(real_session, "CREATE (:Album {uuid: 'dup'})").to_a
        expect do
          adaptor.query(real_session, "CREATE (:Album {uuid: 'dup'})").to_a
        end.to raise_error(::Neo4j::Core::CypherSession::SchemaErrors::ConstraintValidationFailedError)
      end
    end

    describe 'Invalid input error' do
      it 'raises an error' do
        expect do
          adaptor.query(real_session, "CRATE (:Album {uuid: 'dup'})").to_a
        end.to raise_error(::Neo4j::Core::CypherSession::CypherError, /Invalid input 'A'/)
      end
    end

    describe 'Clause ordering error' do
      it 'raises an error' do
        expect do
          adaptor.query(real_session, "RETURN a CREATE (a:Album {uuid: 'dup'})").to_a
        end.to raise_error(::Neo4j::Core::CypherSession::CypherError, /RETURN can only be used at the end of the query/)
      end
    end
  end

  describe 'schema inspection' do
    before { delete_schema(real_session) }
    before do
      create_constraint(real_session, :Album, :al_id, type: :unique)
      create_constraint(real_session, :Album, :name, type: :unique)
      create_constraint(real_session, :Song, :so_id, type: :unique)

      create_index(real_session, :Band, :ba_id)
      create_index(real_session, :Band, :fisk)
      create_index(real_session, :Person, :name)
    end

    describe 'constraints' do
      let(:label) {}
      subject { adaptor.constraints(real_session) }

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
      subject { adaptor.indexes(real_session) }

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
