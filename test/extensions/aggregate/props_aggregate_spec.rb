$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../..")

require 'neo4j'
require 'neo4j/extensions/aggregate'
require 'spec_helper'


PropsAggregate = Neo4j::Aggregate::PropsAggregate


describe Neo4j::Aggregate::PropGroup do
  before(:each) { Neo4j::Transaction.new}
  after(:each) {stop}

  it "should return an enumeration of all properties on one node" do
    # given
    group_node = Neo4j::Aggregate::PropGroup.new
    group_node.group_by = "name,age"
    group_node.aggregate = Neo4j::Node.new {|n| n[:name] = 'kalle'; n[:age] = 23}

    # then
    group_node.should include('kalle', 23)
  end

end


describe Neo4j::Aggregate::PropsAggregate do
  before(:each) do
    start
    Neo4j::Transaction.new
    @registrations = []
  end

  after(:each) do
    stop
    @registrations.each {|reg| reg.unregister}
  end


  describe "#aggregate_size" do
    it "should be 0 when a property aggregate is created" do
      pa = PropsAggregate.new
      pa.aggregate_size.should == 0
    end

    it "should be 1 when one node is aggregated" do
      node = Neo4j::Node.new
      node[:name] = 'andreas'

      # when
      pa = PropsAggregate.new
      pa.aggregate(:q1).props(:name).on(node).execute

      # then
      pa.aggregate_size.should == 1
    end

    it "should be 1 when one node is aggregated, even if there are no properties to aggregate" do
      node = Neo4j::Node.new
      node[:name] = 'andreas'

      # when
      pa = PropsAggregate.new
      pa.aggregate(:q1).props(:plong).on(node).execute

      # then
      pa.aggregate_size.should == 1
    end

    it "should be 2 when two nodes are aggregated" do
      node1 = Neo4j::Node.new
      node1[:name] = 'andreas'
      node2 = Neo4j::Node.new
      node2[:name] = 'kalle'

      # when
      pa = PropsAggregate.new
      pa.aggregate(:q1).props(:name).on([node1, node2]).execute

      # then
      pa.aggregate_size.should == 2
    end

  end


  describe "#aggregate(id).props(properties).on(some nodes).execute" do
    it "should create one group on one node" do
      node = Neo4j::Node.new
      node[:name] = 'andreas'
      node[:colour] = 'blue'

      # when
      q1 = PropsAggregate.new
      q1.aggregate(:q1).props(:colour, :name).on(node).execute

      # then
      node.aggregate_groups(:q1).should include("andreas", "blue")
    end

    it "should create two groups for two nodes" do
      node1 = Neo4j::Node.new
      node1[:name] = 'andreas'
      node1[:colour] = 'blue'

      node2 = Neo4j::Node.new
      node2[:name] = 'kalle'
      node2[:colour] = 'blue'

      # when
      q1 = PropsAggregate.new
      q1.aggregate(:q1).props(:colour, :name).on([node1, node2]).execute

      # then
      node1.aggregate_groups(:q1).should include("andreas", "blue")
      node2.aggregate_groups(:q1).should include("kalle", "blue")
    end

    it "should return an enumeration of all properties on the aggregate node" do
      node1 = Neo4j::Node.new
      node1[:name] = 'andreas'
      node1[:colour] = 'blue'

      node2 = Neo4j::Node.new
      node2[:name] = 'kalle'
      node2[:colour] = 'blue'

      # when
      q1 = PropsAggregate.new
      q1.aggregate(:q1).props(:colour, :name).on([node1, node2]).execute

      # then
      q1.should include("andreas", "blue", "kalle")
      [*q1].size.should == 4
    end

    it "should allow to create different aggregate groups from the same aggregate node" do
      node = Neo4j::Node.new
      node[:surename] = 'andreas'
      node[:lastname] = 'ronge'
      node[:phone] = '1234'
      node[:mobile] = '5678'

      # when
      ag = PropsAggregate.new
      ag.aggregate(:name).props(:surename, :lastname).on(node).execute
      ag.aggregate(:tel).props(:phone, :mobile).on(node).execute

      # then
      node.aggregate_groups(:name).should include("andreas", "ronge")
      node.aggregate_groups(:tel).should include("1234", "5678")
    end

    it "should delete all groups if node is deleted" do
      node = Neo4j::Node.new
      node[:surename] = 'andreas'
      node[:lastname] = 'ronge'
      node[:phone] = '1234'
      node[:mobile] = '5678'
      ag = PropsAggregate.new
      ag.aggregate(:name).props(:surename, :lastname).on(node).execute
      ag.aggregate(:tel).props(:phone, :mobile).on(node).execute

      # when
      node.del

      # then
      node.aggregate_groups(:name).should be_nil
      node.aggregate_groups(:tel).should be_nil
    end
  end


  describe "#aggregate(id).props(properties).on(Class)" do
    before(:all) do
      class Company
        include Neo4j::NodeMixin
        property :month, :revenue
      end
    end

    after(:all) do
      undefine_class :Company
    end

    before(:each) { @registrations = []}
    after(:each) { @registrations.each {|r| r.unregister}}

    it "should create aggregate groups when nodes/properties of the specified class is created" do
      # given
      pa = PropsAggregate.new
      @registrations << pa.aggregate(:q1).on(Company).props(:jan, :feb, :mars)
      @registrations << pa.aggregate(:q2).on(Company).props(:april, :may, :june)

      # when
      c1 = Company.new
      c1[:jan] = 100
      c1[:feb] = 200
      c1[:mars] = 300
      c1[:april] = 400
      c1[:may] = 500
      c1[:june] = 600

      c2 = Company.new
      c2[:jan] = 1100
      c2[:feb] = 1200
      c2[:mars] = 1300
      c2[:april] = 1400
      c2[:may] = 1500
      c2[:june] = 1600

      # then
      c1.aggregate_groups(:q1).should include(100, 200, 300)
      c2.aggregate_groups(:q2).should include(1400, 1500, 1600)

      pa.should include(100, 200, 300, 1100, 1200, 1300)
      pa.should include(400, 500, 600, 1400, 1500, 1600)
    end

    it "should update the aggregate when a node changes" do
      q1 = PropsAggregate.new
      @registrations << q1.aggregate(:q1).on(Company).props(:jan, :feb, :mars)

      # given
      c1 = Company.new
      c1[:jan] = 100
      c1[:feb] = 200
      q1.should include(100, 200)

      # when
      c1[:feb] = 42

      # then
      q1.should_not include(200)
      q1.should include(42)
    end

    it "should delete the group when the node is deleted" do
      q1 = PropsAggregate.new
      @registrations << q1.aggregate(:q1).on(Company).props(:jan, :feb, :mars)

      # given
      c1 = Company.new
      c1[:jan] = 100
      c1[:feb] = 200
      q1.should include(100, 200)
      q1.groups.size.should == 1
      Neo4j.load_node(q1.neo_id).should_not be_nil

      # when
      c1.del

      # then
      q1.groups.size.should == 0
      q1.should_not include(100)
      q1.should_not include(200)
    end

  end

  describe "#groups" do
    it "should contain one group for each node that has been aggregated" do
      node1 = Neo4j::Node.new
      node1[:name] = 'andreas'
      node1[:colour] = 'blue'

      node2 = Neo4j::Node.new
      node2[:name] = 'kalle'
      node2[:colour] = 'blue'

      # when
      pa = PropsAggregate.new
      pa.aggregate(:foo).props(:colour, :name).on([node1, node2]).execute

      # then
      pa.groups.size.should == 2
      pa.groups.should include(node1.aggregate_groups(:foo))
      pa.groups.should include(node2.aggregate_groups(:foo))
    end
  end

  describe "#aggregate(id).props(properties).on(nodes).with(property){...}" do

    before(:all) do
      class Company
        include Neo4j::NodeMixin
        property :month, :revenue
      end
    end

    after(:all) do
      undefine_class :Company
    end


    it "should be possible to sum the values of a set of properties" do
      # given
      q1 = PropsAggregate.new(:q1)
      @registrations << q1.aggregate(:q1).on(Company).props(:jan, :feb, :mars).with(:sum){|sum, val, prev_val| sum + val - prev_val}
      q2 = PropsAggregate.new(:q2)
      @registrations << q2.aggregate(:q2).on(Company).props(:april, :may, :june).with(:sum){|sum, val, prev_val| sum + val - prev_val}

      # when
      c1 = Company.new
      c1[:jan] = 100
      c1[:feb] = 200
      c1[:mars] = 300
      c1[:april] = 400
      c1[:may] = 500
      c1[:june] = 600

      # then
      c1.aggregate_groups(:q1)[:sum].should == 100+200+300
      c1.aggregate_groups(:q2)[:sum].should == 400+500+600
    end

  end
end

#
#
#end