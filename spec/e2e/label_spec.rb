require 'spec_helper'

LabelTest = UniqueClass.create(:LabelTest) do
  include Neo4j::ActiveNode
end

describe "Neo4j::ActiveNode" do
  describe "labels" do
    it "returns the label of the class" do
      expect(LabelTest.create.labels).to eq([:LabelTest])
    end
  end

  describe 'add_label' do
    it "can add one label" do
      node = LabelTest.create
      node.add_label(:foo)
      expect(node.labels).to match_array([:LabelTest, :foo])
    end

    it "can add two label" do
      node = LabelTest.create
      node.add_label(:foo, :bar)
      expect(node.labels).to match_array([:LabelTest, :foo, :bar])
    end

  end


  describe 'remove_label' do
    it "can remove one label" do
      node = LabelTest.create
      node.add_label(:foo)
      node.remove_label(:foo)
      expect(node.labels).to match_array([:LabelTest])
    end

    it "can add two label" do
      node = LabelTest.create
      node.add_label(:foo, :bar, :baaz)
      node.remove_label(:foo, :baaz)
      expect(node.labels).to match_array([:LabelTest, :bar])
    end

  end
end