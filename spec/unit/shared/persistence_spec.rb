require 'spec_helper'

describe Neo4j::Shared::Persistence do
  before do
    stub_const('MyModel', Class.new do
                            include Neo4j::Shared::Persistence
                            include Neo4j::Shared::Property

                            property :name
                            property :age, type: Integer

                            def self.extract_association_attributes!(props)
                              props
                            end
                          end)
    allow(MyModel).to receive(:cached_class?).and_return false
  end

  let(:node) { MyModel.new }

  describe 'props_for_create' do
    it 'sets timestamps' do
      expect(node).to receive(:inject_timestamps!)
      node.props_for_create
    end

    it 'returns a hash of props' do
      node.name = 'Chris'
      node.age = 31
      props = node.props_for_create
      expect(props).to have_key(:name)
      expect(props).to have_key(:age)
    end

    it 'rebuilds each time called' do
      props1 = node.props_for_create
      props2 = node.props_for_create
      expect(props1.object_id).not_to eq(props2.object_id)
    end
  end

  describe 'props_for_update' do
    it 'returns only changed properties' do
      props = node.props_for_update
      expect(props).not_to have_key('name')
      expect(props).not_to have_key('age')
      node.name = 'Jasmine'
      expect(node.props_for_update).to have_key('name')
    end

    it 'updates the updated_at timestamp' do
      MyModel.property :updated_at, type: DateTime
      allow(node).to receive(:changed?).and_return true
      expect(node.props_for_update).to have_key('updated_at')
    end
  end

  describe 'props_for_persistence' do
    it 'calls the props_for_{action} method appropriate for object state' do
      expect(node).to receive(:_persisted_obj).and_return(false)
      expect(node).to receive(:props_for_create)
      node.props_for_persistence

      expect(node).to receive(:_persisted_obj).and_return(true)
      expect(node).to receive(:props_for_update)
      node.props_for_persistence
    end
  end
end
