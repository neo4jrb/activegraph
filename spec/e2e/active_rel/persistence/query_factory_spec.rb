describe Neo4j::ActiveRel::Persistence::QueryFactory do
  describe '#build!' do
    describe 'non-subclassed' do
      before do
        stub_active_node_class('FromClass') do
          property :created_at, type: Integer
          property :updated_at, type: Integer
          property :name
          has_many :out, :to_classes, type: 'HAS_REL'
        end

        stub_active_node_class('ToClass') do
          property :created_at, type: Integer
          property :updated_at, type: Integer
          property :name
        end

        stub_active_rel_class('RelClass') do
          type 'HAS_REL'
          from_class :FromClass
          to_class :ToClass

          property :score

          def self.count
            Neo4j::Session.current.query
              .match('(from:FromClass)-[r:HAS_REL]->()')
              .pluck('COUNT(r)').first
          end
        end
      end

      let(:from_node) { FromClass.new(name: 'foo') }
      let(:to_node) { ToClass.new(name: 'bar') }
      let(:rel) { RelClass.new(from_node: from_node, to_node: to_node, score: 10) }

      let(:graph_objects) do
        {
          from_node: from_node,
          to_node: to_node,
          rel: rel
        }
      end

      it 'creates nodes and the rel' do
        expect { rel.save }.to change { FromClass.count + ToClass.count + RelClass.count }.by(3)
      end

      it 'marks all objects as persisted' do
        expect do
          rel.save
        end.to change { [from_node, to_node, rel].all?(&:persisted?) }.from(false).to(true)
      end

      it 'adds uuids to nodes' do
        expect do
          rel.save
        end.to change { [from_node, to_node].all? { |o| o.uuid.nil? } }.from(true).to(false)
      end

      it 'validates unpersisted nodes' do
        [from_node, to_node].each do |o|
          expect(o).to receive(:valid?).and_call_original
        end
        rel.save
      end

      it 'fires :create_callbacks on unpersisted nodes' do
        [from_node, to_node].each do |o|
          expect(o).to receive(:run_callbacks).with(:create).and_call_original
        end
        rel.save
      end
    end

    describe 'subclassed' do
      before do
        superclass = stub_active_node_class('ParentClass') do
          property :created_at, type: Integer
          property :updated_at, type: Integer
        end

        stub_named_class('FromClass', superclass) do
          has_many :out, :to_classes, type: 'HAS_REL'
        end

        stub_named_class('ToClass', superclass) do
          property :created_at, type: Integer
          property :updated_at, type: Integer
        end

        stub_active_rel_class('RelClass') do
          type 'HAS_REL'
          from_class :FromClass
          to_class :ToClass

          def self.count
            Neo4j::Session.current.query
              .match('(from:FromClass:ParentClass)-[r:HAS_REL]->()')
              .pluck('COUNT(r)').first
          end
        end
      end

      let(:from_node) { FromClass.new }
      let(:to_node) { ToClass.new }
      let(:rel) { RelClass.new(from_node: from_node, to_node: to_node) }

      it 'creates nodes and the rel' do
        expect { rel.save }.to change { FromClass.count + ToClass.count + RelClass.count }.by(3)
      end

      it 'subclasses correctly' do
        expect { rel.save }.to change { ParentClass.count }.by(2)
      end
    end
  end
end
