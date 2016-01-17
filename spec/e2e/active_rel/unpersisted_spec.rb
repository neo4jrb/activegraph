describe 'ActiveRel unpersisted handling' do
  before(:each) do
    clear_model_memory_caches
    delete_db

    stub_named_class('ToClass')

    stub_named_class('MyRelClass')

    stub_active_node_class('FromClass') do
      before_create :log_before
      after_create :log_after
      property :name
      property :created_at, type: Integer
      property :updated_at, type: Integer
      property :before_run, type: Neo4j::Shared::Boolean
      property :after_run

      has_many :out, :others, model_class: 'ToClass', rel_class: 'MyRelClass'

      def log_before
        self.before_run = true
      end

      def log_after
        self.after_run = true
      end
    end

    stub_active_node_class('ToClass') do
      before_create :log_before
      after_create :log_after
      property :created_at, type: Integer
      property :updated_at, type: Integer
      property :before_run, type: Neo4j::Shared::Boolean
      property :after_run

      has_many :in, :others, model_class: 'FromClass', rel_class: 'MyRelClass'
      has_many :in, :string_others, model_class: 'FromClass', rel_class: 'MyRelClass'

      def log_before
        self.before_run = true
      end

      def log_after
        self.after_run = true
      end
    end

    stub_active_rel_class('MyRelClass') do
      from_class :FromClass
      to_class :ToClass
      type 'rel_class_type'

      property :score, type: Integer
      property :links
      serialize :links
    end
  end

  describe 'unpersisted nodes' do
    let(:from_node) { FromClass.new }
    let(:to_node) { ToClass.new }
    let(:rel) { MyRelClass.new(from_node: from_node, to_node: to_node) }

    context 'both nodes unpersisted' do
      context 'from_node invalid' do
        it 'fails with an error' do
          expect(from_node).to receive(:valid?).and_return(false)
          expect { rel.save }.to raise_error Neo4j::ActiveRel::Persistence::RelCreateFailedError
        end
      end

      context 'to_node invalid' do
        it 'fails with an error' do
          expect(from_node).to receive(:valid?).and_return(true)
          expect(to_node).to receive(:valid?).and_return(false)
          expect { rel.save }.to raise_error Neo4j::ActiveRel::Persistence::RelCreateFailedError
        end
      end

      context 'both nodes valid' do
        it 'triggers both :before_create callbacks' do
          [from_node, to_node].each do |node|
            expect(node).to receive(:run_callbacks).at_least(1).times.and_call_original
          end
          rel.save
        end

        it 'triggers both :after_create callbacks' do
          expect { rel.save }.to change { [from_node, to_node].all?(&:after_run) }.from(false).to(true)
        end

        it 'persists both nodes' do
          expect { rel.save }.to change { [from_node, to_node].all?(&:persisted?) }.from(false).to true
          expect(from_node.uuid).not_to be_nil
        end

        context 'with creates_unique set' do
          before { MyRelClass.creates_unique(:none) }

          it 'will create duplicate nodes' do
            from_node.name = 'Chris'
            from_node.save
            expect { MyRelClass.create(FromClass.new(name: 'Chris'), ToClass.new) }.to change { FromClass.count }.by(1)
          end

          it 'will not create duplicate rels' do
            expect { MyRelClass.create(from_node, to_node) }.to change { from_node.others.count }.by(1)
            expect { MyRelClass.create(from_node, to_node) }.not_to change { from_node.others.count }
          end
        end
      end
    end

    context 'one node unpersisted' do
      let(:from_node) { FromClass.new }
      let(:to_node)   { ToClass.create }

      it 'it does not check validity of the persisted node' do
        expect(to_node).not_to receive(:valid?)
        expect { rel.save }.not_to raise_error
      end

      it 'triggers only the unpersisted before_create callback' do
        expect(to_node).not_to receive(:run_callbacks)
        expect(from_node).to receive(:run_callbacks).and_call_original
        expect { rel.save }.to change { from_node.persisted? }
      end

      it 'does not change the uuid of the persisted node' do
        expect { rel.save }.not_to change { to_node.uuid }
      end

      it 'does not change the timestamps of the persisted node' do
        expect { rel.save }.not_to change { to_node.updated_at }
      end
    end
  end
end
