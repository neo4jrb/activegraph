require 'spec_helper'

describe "Specs for random things that have been reported" do
  context 'https://twitter.com/jpsandlin/status/642162044645560320' do
    before do
      stub_active_node_class('Thing') do
        property :dog, default: ''
        property :bee
      end
    end
    it 'does not set fields to their default values on save' do
      thing = Thing.create(dog: 'foo')
      thing.bee = 'buzz'
      thing.save
      thing.reload

      expect(thing.dog).not_to eq('')
    end
  end
end