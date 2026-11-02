module ActiveGraph
  module Shared
    describe QueryFactory do
      before do
        stub_node_class('NodeClass') { property :name }

        stub_relationship_class('RelClass') do
          from_class false
          to_class false
          type 'REL'
          property :score
        end

        stub_relationship_class('UniqueRelClass') do
          from_class false
          to_class false
          type 'UNIQUE_REL'
          creates_unique on: :score
          property :score
          property :note
        end
      end

      describe '#query' do
        let(:query) { described_class.create(graph_obj, :obj).query }

        def persisted(graph_obj, neo_id)
          allow(graph_obj).to receive_messages(persisted?: true, neo_id: neo_id)
          graph_obj
        end

        context 'with an unpersisted node' do
          let(:graph_obj) { NodeClass.new(name: 'foo') }

          it 'creates it and sets all properties from one map parameter' do
            expect(query.to_cypher).to eq('CREATE (obj:`NodeClass`) SET obj = $obj_params')
            expect(query.parameters[:obj_params]).to include(name: 'foo')
          end
        end

        context 'with a persisted node' do
          let(:graph_obj) { persisted(NodeClass.new, '4:db:1') }

          it 'matches it by element id' do
            expect(query.to_cypher).to eq('MATCH (obj) WHERE elementId(obj) = $obj_id')
            expect(query.parameters).to eq(obj_id: '4:db:1')
          end
        end

        context 'with an unpersisted rel' do
          let(:graph_obj) { RelClass.new(score: 9) }

          it 'creates it and sets its properties' do
            expect(query.to_cypher)
              .to eq('CREATE (from_node)-[obj:`REL`]->(to_node) ' \
                     'SET obj.uuid = $setter_obj_uuid, obj.score = $setter_obj_score')
            expect(query.parameters[:setter_obj_score]).to eq(9)
          end
        end

        context 'with an unpersisted unique rel' do
          let(:graph_obj) { UniqueRelClass.new(score: 9, note: 'n') }

          it 'merges on the unique properties and sets the rest' do
            expect(query.to_cypher)
              .to eq('MERGE (from_node)-[obj:`UNIQUE_REL` {score: $obj_create_props_score}]->(to_node) ' \
                     'SET obj.uuid = $setter_obj_uuid, obj.note = $setter_obj_note')
            expect(query.parameters).to include(obj_create_props_score: 9, setter_obj_note: 'n')
          end
        end

        context 'with a persisted rel' do
          let(:graph_obj) { persisted(RelClass.new, '5:db:1') }

          it 'matches it by element id' do
            expect(query.to_cypher).to eq('MATCH (from_node)-[obj]->() WHERE elementId(obj) = $obj_id')
            expect(query.parameters).to eq(obj_id: '5:db:1')
          end
        end
      end

      describe '.factory_for' do
        subject { described_class.factory_for(graph_obj) }

        context 'with Relationship' do
          let(:graph_obj) { RelClass.new }
          it { is_expected.to eq RelQueryFactory }
        end

        context 'with Node' do
          let(:graph_obj) { NodeClass.new }
          it { is_expected.to eq NodeQueryFactory }
        end

        context 'with RelatedNode' do
          let(:graph_obj) { ActiveGraph::Relationship::RelatedNode.new(NodeClass.new) }
          it { is_expected.to eq NodeQueryFactory }
        end

        context 'with anything else' do
          let(:graph_obj) { 'foo' }
          it { expect { subject }.to raise_error RuntimeError, /Unable to find factory for/ }
        end
      end
    end
  end
end
