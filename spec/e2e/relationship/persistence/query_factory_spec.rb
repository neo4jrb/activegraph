describe ActiveGraph::Relationship::Persistence::QueryFactory do
  describe '#build!' do
    describe 'non-subclassed' do
      before do
        stub_node_class('FromClass') do
          property :created_at, type: Integer
          property :updated_at, type: Integer
          property :name
          has_many :out, :to_classes, type: 'HAS_REL'
          has_one :out, :to_class, type: 'HAS_REL_2'
          has_one :out, :rel_3, rel_class: :Rel3Class, model_class: :ToClass
          has_one :in, :rel_4_inverse, rel_class: :Rel4Class, model_class: :ToClass
        end

        stub_node_class('ToClass') do
          property :created_at, type: Integer
          property :updated_at, type: Integer
          property :name
          has_one :in, :from_class, type: 'HAS_REL'
          has_many :in, :from_classes, type: 'HAS_REL_2'
          has_one :in, :rel_3_inverse, rel_class: :Rel3Class, model_class: :FromClass
          has_one :out, :rel_4, rel_class: :Rel4Class, model_class: :FromClass
        end

        stub_relationship_class('RelClass') do
          type 'HAS_REL'
          from_class :FromClass
          to_class :ToClass

          property :score

          def self.count
            new_query
              .match('(from:FromClass)-[r:HAS_REL]->()')
              .pluck('COUNT(r)').first
          end
        end

        stub_relationship_class('Rel2Class') do
          type 'HAS_REL_2'
          from_class :FromClass
          to_class :ToClass

          property :score
        end

        stub_relationship_class('Rel3Class') do
          type 'REL'
          from_class :FromClass
          to_class :ToClass

          property :score_3
        end

        stub_relationship_class('Rel4Class') do
          type 'REL'
          from_class :ToClass
          to_class :FromClass

          property :score_4
        end
      end

      let(:from_node) { FromClass.new(name: 'foo') }
      let(:to_node) { ToClass.new(name: 'bar') }
      let(:rel) { RelClass.new(from_node: from_node, to_node: to_node, score: 10) }

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
        end.to change { [from_node, to_node].all? { |o| o.id.nil? } }.from(true).to(false)
      end

      it 'validates unpersisted nodes' do
        [from_node, to_node].each do |o|
          expect(o).to receive(:valid?).and_call_original
        end
        rel.save
      end

      it 'fires :create_callbacks on unpersisted nodes' do
        [from_node, to_node].each do |o|
          allow(o).to receive(:run_callbacks).with(:validation)
          expect(o).to receive(:run_callbacks).with(:create).and_call_original
        end
        rel.save
      end

      it 'delets has_one rel from to_node when new relation is created' do
        from_node_two = FromClass.new(name: 'foo-2')
        rel.save
        RelClass.new(from_node: from_node_two, to_node: to_node, score: 10).save
        expect(from_node.reload.to_classes).to be_empty
      end

      it 'delets has_one rel from from_node when new relation is created' do
        to_node_two = ToClass.new(name: 'bar-2')
        Rel2Class.new(from_node: from_node, to_node: to_node, score: 10).save
        Rel2Class.new(from_node: from_node, to_node: to_node_two, score: 10).save
        expect(to_node.reload.from_classes).to be_empty
      end

      it 'deletes correct has_one rel in case of two relationships with same type' do
        f1 = FromClass.new(name: 'foo-1')
        f2 = FromClass.new(name: 'foo-2')
        t1 = ToClass.new(name: 'bar-1')
        t2 = ToClass.new(name: 'bar-2')
        Rel3Class.new(from_node: f1, to_node: t1, score_3: 10).save
        Rel4Class.new(from_node: t2, to_node: f2, score_4: 10).save
        Rel3Class.new(from_node: f2, to_node: t1, score_3: 100).save
        expect(f1.reload.rel_3).to be_nil 
        expect(f2.reload.rel_3.id).to eq(t1.id)
      end
    end

    describe 'subclassed' do
      before do
        superclass = stub_node_class('ParentClass') do
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

        stub_relationship_class('RelClass') do
          type 'HAS_REL'
          from_class :FromClass
          to_class :ToClass

          def self.count
            ActiveGraph::Base.new_query
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
