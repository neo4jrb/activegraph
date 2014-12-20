require 'spec_helper'
require "shared_examples/new_model"
require "shared_examples/loadable_model"
require "shared_examples/saveable_model"
require 'shared_examples/creatable_model'
require 'shared_examples/destroyable_model'

class BasicModel
  include Neo4j::ActiveNode
  property :name
  property :a
  property :b
end

describe BasicModel do
  it_should_behave_like "new model"
  it_should_behave_like "loadable model"
  it_should_behave_like "saveable model"
  it_should_behave_like "creatable model"
  it_should_behave_like "destroyable model"
  it_should_behave_like "updatable model"

  it 'has a label' do
    subject.class.create!.labels.should == [:BasicModel]
  end

  context "when there's lots of them" do
    before(:each) do
      subject.class.delete_all
      3.times { subject.class.create! }
    end

    it "should be possible to #count" do
      subject.class.count.should == 3
    end

    it "should be possible to #delete_all" do
      expect(subject.class).not_to receive(:all)
      expect(subject.class.count).to eq 3
      subject.class.delete_all
      expect(subject.class.count).to eq 0
    end

    it 'should be possible to #destroy_all' do
      expect(subject.class).to receive(:all).and_return(subject.class.all)
      expect(subject.class.count).to eq 3
      subject.class.destroy_all
      expect(subject.class.count).to eq 0
    end
  end
end
