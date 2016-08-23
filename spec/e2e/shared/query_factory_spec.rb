describe Neo4j::Shared::QueryFactory do
  let!(:factory_from_class) do
    stub_active_node_class('FactoryFromClass') do
      property :name
    end
  end

  before do
    stub_active_node_class('FactoryToClass') do
      property :name
    end

    stub_active_rel_class('FactoryRelClass') do
      from_class 'FactoryFromClass'
      to_class 'FactoryToClass'
      property :score

      def self.count
        Neo4j::Session.current.query.match('(n)-[r:FACTORY_REL_CLASS]->()').pluck('count(r)').first
      end
    end
  end

  let(:from_node) { FactoryFromClass.new(name: 'foo') }
  let(:to_node) { FactoryToClass.new(name: 'bar') }
  let(:rel) { FactoryRelClass.new(score: 9000) }
  let(:from_node_factory) { described_class.create(from_node, :from_node) }
  let(:to_node_factory) { described_class.create(to_node, :to_node) }
  let(:rel_factory) { described_class.create(rel, :rel) }

  describe 'nodes' do
    context 'unpersisted' do
      it 'builds a query to create' do
        expect do
          expect(from_node_factory.query.pluck(:from_node).first.labels).to eq FactoryFromClass.mapped_label_names
        end.to change { FactoryFromClass.count }
      end

      context 'with a value that might be interpreted as a prop' do
        let(:from_node) { FactoryFromClass.new(name: '{Tricky .Value}') }
        it 'creates without error' do
          expect do
            expect(from_node_factory.query.pluck(:from_node).first.labels).to eq FactoryFromClass.mapped_label_names
          end.to change { FactoryFromClass.where(name: from_node.name).count }
        end
      end

      context 'with multiple labels' do
        before do
          stub_named_class('FromSubclass', factory_from_class { include Neo4j::ActiveNode })
          FromSubclass.property :other_prop
        end

        let(:from_node) { FromSubclass.new(other_prop: '{Foo .property}') }

        it 'creates the node with all labels' do
          expect do
            expect(from_node_factory.query.pluck(:from_node).first.labels.sort).to eq FromSubclass.mapped_label_names.sort
          end.to change { FromSubclass.where(name: from_node.name).count }
        end
      end
    end

    context 'persisted' do
      before { from_node.save }

      it 'builds a query to match' do
        expect do
          expect(from_node_factory.query.pluck(:from_node).first.class.name).to eq 'FactoryFromClass'
        end.not_to change { FactoryFromClass.count }
      end
    end
  end

  describe 'rels' do
    context 'unpersisted' do
      # In this case, it creates labelless nodes on either side, too
      it 'builds a query to create' do
        expect do
          expect(rel_factory.query.pluck(:rel).first).to be_a(FactoryRelClass)
        end.to change { FactoryRelClass.count }
      end

      context 'with a value that might be interpreted as a prop' do
        let(:rel) { FactoryRelClass.new(score: '{9000 ....}') }

        it 'creates without error' do
          expect do
            expect(rel_factory.query.pluck(:rel).first).to be_a(FactoryRelClass)
          end.to change { FactoryRelClass.count }
        end
      end
    end

    context 'persisted' do
      before do
        rel.from_node = from_node
        rel.to_node = to_node
        rel.save
      end

      it 'builds a query to match' do
        expect do
          expect(rel_factory.query.pluck(:rel).first.class.name).to eq 'FactoryRelClass'
        end.not_to change { FactoryRelClass.count }
      end
    end
  end

  describe 'base_query' do
    context 'when not already set' do
      it 'creates a new Query object' do
        expect(Neo4j::Core::Query).to receive(:new).and_call_original
        expect(from_node_factory.base_query).to be_a(Neo4j::Core::Query)
      end
    end

    context 'when set' do
      before { from_node_factory.instance_variable_set(:@base_query, Neo4j::Session.current.query) }

      it 'returns the existing query' do
        expect(Neo4j::Core::Query).not_to receive(:new)
        expect(from_node_factory.base_query).to be_a(Neo4j::Core::Query)
      end

      it 'is built upon' do
        expect do
          to_node_factory.base_query = from_node_factory.query
        end.to change { to_node_factory.query.to_cypher.include?('CREATE (from_node:`FactoryFromClass`') }.from(false).to(true)
      end
    end

    describe '#base_query=' do
      it 'changes the value of #base_query' do
        expect { from_node_factory.base_query = Neo4j::Session.current.query }.to change { from_node_factory.base_query }
      end
    end
  end
end
