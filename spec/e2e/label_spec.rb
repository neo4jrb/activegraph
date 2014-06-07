require 'spec_helper'


describe "Neo4j::ActiveNode" do
  let(:clazz) do
    UniqueClass.create() do
      include Neo4j::ActiveNode
    end
  end

  let(:label_name) do
    clazz.to_s.to_sym
  end
  
  describe "labels" do
    it "returns the label of the class" do
      expect(clazz.create.labels).to eq([label_name])
    end
  end

  describe 'add_label' do
    it "can add one label" do
      node = clazz.create
      node.add_label(:foo)
      expect(node.labels).to match_array([label_name, :foo])
    end

    it "can add two label" do
      node = clazz.create
      node.add_label(:foo, :bar)
      expect(node.labels).to match_array([label_name, :foo, :bar])
    end

  end


  describe 'remove_label' do
    it "can remove one label" do
      node = clazz.create
      node.add_label(:foo)
      node.remove_label(:foo)
      expect(node.labels).to match_array([label_name])
    end

    it "can add two label" do
      node = clazz.create
      node.add_label(:foo, :bar, :baaz)
      node.remove_label(:foo, :baaz)
      expect(node.labels).to match_array([label_name, :bar])
    end

  end

end
