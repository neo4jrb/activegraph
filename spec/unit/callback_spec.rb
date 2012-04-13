require 'spec_helper'

describe Neo4j::Rails::Callbacks, :type => :unit do

  without_database

  let(:new_node) { MockNode.new }
  let(:new_model) { klass.new }
  let(:saved_model) { klass.create}
  let(:klass) do
    Class.new do
      def self.to_s
        "MyObject2"
      end
      include Neo4j::NodeMixin
      include Neo4j::Rails::Persistence
      include Neo4j::Rails::NodePersistence

      include Neo4j::Rails::Attributes
      include Neo4j::Rails::Validations
      include Neo4j::Rails::Callbacks
      include Neo4j::Rails::Relationships

      property :desc, :name

      def set_desc
        self.desc = self.name
      end
    end
  end

  describe "after_initialize" do
    it "is called" do
      klass.after_initialize :set_desc
      k = klass.new(:name => 'foo')
      k.desc.should == 'foo'
    end
  end
end
