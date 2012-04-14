require 'spec_helper'

describe Neo4j::Rails::Relationships, :type => :unit do

  without_database

  let(:klass) do
    Class.new do
      def self.to_s
        "MyObject2"
      end
      include Neo4j::Rails::Relationships
    end
  end

  let(:node) do
    n = klass.new
    n.initialize_relationships
    n
  end

  let(:other_node) do
    create_model.new
  end

  context "node is unpersisted" do
    before do
      node.stub(:persisted?).and_return(false)
      node.stub(:new_record?).and_return(true)
    end

    describe "node.rels(:outgoing, :foo).build(:since => 1994)" do
      before do
        node.rels(:outgoing, :foo).build(:since => 1994)
      end

      it "creates a relationship with attributes" do
        rel =node.rel(:outgoing, :foo)
        rel[:since].should == 1994
      end
    end

    describe "node.rels(:outgoing, :foo).create(:since => 1994)" do
      it "creates a relationship with attributes" do
        other = mock("other")
        other.should_receive(:save).and_return(true)
        Neo4j::Rails::Model.should_receive(:new).and_return(other)
        rel = mock("Relationship")
        Neo4j::Rails::Relationship.should_receive(:new).with(:foo, node, other, :since => 1994).and_return(rel)
        node.rels(:outgoing, :foo).create(:since => 1994)
      end
    end

    describe "node.outgoing(:foo) << other_node" do
      before do
        node.outgoing(:foo) << other_node
      end

      describe "node.nodes(:outgoing, :foo)" do
        subject { node.nodes(:outgoing, :foo)}
        it { should include(other_node) }
        its(:count) { should == 1 }
      end

      describe "node.node(:outgoing, :foo)" do
        subject { node.node(:outgoing, :foo)}
        before { node.stub(:_java_node).and_return(nil)}
        it { should ==  other_node }
      end

      describe "node.outgoing(:foo)" do
        subject { node.outgoing(:foo) }
        it { should include(other_node) }
        its(:count) { should == 1 }
      end

      describe "node.incoming(:foo)" do
        subject { node.incoming(:foo) }
        it { should_not include(other_node) }
        its(:count) { should == 0 }
      end

      describe "node.rel(:outgoing, :foo)" do
        it "return a relationship with start_end and end_node set" do
          rel = node.rel(:outgoing, :foo)
          rel.start_node.should == node
          rel.end_node.should == other_node
        end
      end

      describe "node.rel?(:outgoing, :foo)" do
        it "should return true" do
          node.rel?(:outgoing, :foo).should be_true
        end
      end

      describe "node.rel(:incoming, :foo)" do
        it "returns nil" do
          node.rel(:incoming, :foo).should be_nil
        end
      end

      describe "node.rel?(:incoming, :foo)" do
        it "should return true" do
          node.rel?(:incoming, :foo).should be_false
        end
      end

      describe "node.rel?(:both, :foo)" do
        it "should return true" do
          node.rel?(:both, :foo).should be_true
        end
      end

      describe "node.rel?(:both, :unknown)" do
        it "should return false" do
          node.rel?(:both, :unknown).should be_false
        end
      end

      describe "write_changed_relationships" do
        before do
          other_node.should_receive(:save).and_return(true)
          node.should_receive(:save).and_return(true)
          node.write_changed_relationships

          node.stub(:persisted?).and_return(true)
          node.stub(:new_record?).and_return(false)
        end

        describe "node.incoming(:foo)" do
          it "saves incoming and outgoing relationships" do
            node.should_receive(:_rels).with(:outgoing, :foo).and_return([])
            node.rels(:outgoing, :foo).should be_empty
          end
        end
      end

    end

    describe "node.incoming(:foo) << other_node" do
      before do
        node.incoming(:foo) << other_node
      end

      describe "node.incoming(:foo)" do
        subject { node.incoming(:foo) }
        it { should include(other_node) }
        its(:count) { should == 1 }
      end

      describe "node.outgoing(:foo)" do
        subject { node.outgoing(:foo) }
        it { should_not include(other_node) }
        its(:count) { should == 0 }
      end

    end


  end


  context "node is persisted" do
    before do
      node.stub(:persisted?).and_return(true)
    end

    describe "node.outgoing(:foo) << other_node" do
      before do
        node.outgoing(:foo) << other_node
      end

      describe "node.outgoing(:foo)" do
        subject { node.outgoing(:foo) }
        before { node.stub(:_rels).with(:outgoing, :foo).and_return([]) }
        it { should include(other_node) }
        its(:count) { should == 1 }
      end

      describe "node.incoming(:foo)" do
        subject { node.incoming(:foo) }
        before { node.stub(:_rels).with(:incoming, :foo).and_return([]) }
        it { should_not include(other_node) }
        its(:count) { should == 0 }
      end

    end

    describe "node.incoming(:foo) << other_node" do
      before do
        node.incoming(:foo) << other_node
      end

      describe "node.incoming(:foo)" do
        subject { node.incoming(:foo) }
        before { node.stub(:_rels).with(:incoming, :foo).and_return([]) }

        it { should include(other_node) }
        its(:count) { should == 1 }
      end

      describe "node.outgoing(:foo)" do
        subject { node.outgoing(:foo) }
        before { node.stub(:_rels).with(:outgoing, :foo).and_return([]) }
        it { should_not include(other_node) }
        its(:count) { should == 0 }
      end

    end
  end

end