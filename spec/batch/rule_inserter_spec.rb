require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Batch::RuleInserter do


  class TestInserter
    attr_reader :created_nodes, :created_rels

    def initialize
      @created_nodes = {}
      @created_rels  = {}
    end
    def create_node(hash={})
      id = @created_nodes.size + 1
      @created_nodes[id] = hash
      id
    end

    def ref_node
      0
    end

    def create_rel(rel_type, from, to)
      id = @created_rels.size + 1
      @created_rels[id] = {:rel_type => rel_type, :from => from, :to => to}
      id
    end

    def set_node_props(node, hash, clazz = Neo4j::Node)
      @created_nodes[node] = hash
      @created_nodes['_classname'] = clazz.to_s
    end

    def node_props(node)
      @created_nodes[node]
    end
  end
  
  def setup_create_rule_node(inserter, clazz, rule_node_id=1)
    inserter.should_receive(:create_node).and_return rule_node_id
    inserter.should_receive(:ref_node).once.and_return 0
    inserter.should_receive(:create_rel) do |*args|
      args.size.should == 3
      args[0].should == clazz.to_s
      args[1].should == 0
      args[2].should == rule_node_id
    end
  end

  it "does not create a rule when there is no rules defined for the given class" do
    clazz = create_node_mixin
    rule_inserter = Neo4j::Batch::RuleInserter.new(mock("inserter"))
    rule_inserter.node_added(mock("node"), {'_classname' => clazz.to_s})
  end

  it "creates a rule node if it does not exist already" do
    clazz = create_node_mixin do
      rule :all
    end

    inserter = mock("inserter")
    setup_create_rule_node(inserter, clazz)
    
    inserter.should_receive(:create_rel) do |*args|
      args.size.should == 3
      args[0].should == :all
      args[1].should == 1
      args[2].should == 2
    end
    
    rule_inserter = Neo4j::Batch::RuleInserter.new(inserter)
    rule_inserter.node_added(2, {'_classname' => clazz.to_s})
  end

  it "evaluates the filter method in the context of the wrapper class if no parameter was provided" do
    called = false
    clazz = create_node_mixin do
      property :age
      this_class = self
      rule(:bar) {self.class.should == this_class; called = true; self.age > 10}
    end
    inserter = mock("inserter")
    setup_create_rule_node(inserter, clazz)

    inserter.should_receive(:create_rel) do |*args|
      args.size.should == 3
      args[0].should == :bar
      args[1].should == 1
      args[2].should == 2
    end

    rule_inserter = Neo4j::Batch::RuleInserter.new(inserter)
    rule_inserter.node_added(2, {'_classname' => clazz.to_s, 'age' => 22})
    called.should be_true
  end


  it "connects with rule node if the filter evaluated to true" do
    called = false
    clazz = create_node_mixin do
      rule(:foo) {|node| called = true; node[:age] > 10}
    end
    inserter = mock("inserter")
    setup_create_rule_node(inserter, clazz)

    inserter.should_receive(:create_rel) do |*args|
      args.size.should == 3
      args[0].should == :foo
      args[1].should == 1
      args[2].should == 2
    end

    rule_inserter = Neo4j::Batch::RuleInserter.new(inserter)
    rule_inserter.node_added(2, {'_classname' => clazz.to_s, 'age' => 42})
    called.should be_true
  end


  it "does not connects with rule node if the filter evaluated to false" do
    called = false
    clazz = create_node_mixin do
      rule(:foo) {|node| called = true; node[:age] > 10}
    end
    inserter = mock("inserter")
    setup_create_rule_node(inserter, clazz)

    rule_inserter = Neo4j::Batch::RuleInserter.new(inserter)
    rule_inserter.node_added(2, {'_classname' => clazz.to_s, 'age' => 8})
    called.should be_true
  end

  it "creates rules for base classes" do
    class BaseClazz
      include Neo4j::NodeMixin
      rule(:foo) {|node| node[:age] > 10}
    end
    class SubClazz < BaseClazz
    end

    inserter = mock("inserter")

    SUBCLASS_CLASS_RULE_NODE, BASE_CLASS_RULE_NODE = [42,43]
    
    inserter.should_receive(:create_node).and_return(SUBCLASS_CLASS_RULE_NODE, BASE_CLASS_RULE_NODE)
    inserter.should_receive(:ref_node).any_number_of_times.and_return 0
    inserter.should_receive(:create_rel).exactly(4) do |*args|
      args.size.should == 3
      case args[1]
        when 0
          case args[0]
            when BaseClazz.to_s
              args[2].should == BASE_CLASS_RULE_NODE
            when SubClazz.to_s
              args[2].should == SUBCLASS_CLASS_RULE_NODE
            else
              fail("Unknown rel #{args[1]}")
          end
        when BASE_CLASS_RULE_NODE
          args[0].should == :foo
          args[2].should == 43
        when SUBCLASS_CLASS_RULE_NODE
          args[0].should == :foo
          args[2].should == 42
        else
          fail("Unknown from #{args[1]}")
      end
    end

    rule_inserter = Neo4j::Batch::RuleInserter.new(inserter)
    rule_inserter.node_added(2, {'_classname' => SubClazz.to_s, 'age' => 88})
  end

  it "works with rule functions" do
    clazz = create_node_mixin do
      rule(:foo, :functions => Neo4j::Rule::Functions::Count.new)
    end


    inserter = TestInserter.new
    rule_inserter = Neo4j::Batch::RuleInserter.new(inserter)
    rule_inserter.node_added(2, {'_classname' => clazz.to_s, 'age' => 88})

    property_key = Neo4j::Rule::Functions::Count.new.rule_node_property('foo')
    inserter.created_nodes[1][property_key].should == 1

    rule_inserter.node_added(3, {'_classname' => clazz.to_s, 'age' => 88})
    inserter.created_nodes[1][property_key].should == 2
  end


  it "works with several rule functions" do
    clazz = create_node_mixin do
      rule(:old, :functions => Neo4j::Rule::Functions::Count.new) {|node| node[:age] > 10}
      rule(:new, :functions => Neo4j::Rule::Functions::Count.new) {|node| node[:age] <= 10}
    end

    inserter = TestInserter.new
    rule_inserter = Neo4j::Batch::RuleInserter.new(inserter)
    rule_inserter.node_added(2, {'_classname' => clazz.to_s, 'age' => 88})

    old_property_key = Neo4j::Rule::Functions::Count.new.rule_node_property('old')
    new_property_key = Neo4j::Rule::Functions::Count.new.rule_node_property('new')
    
    inserter.created_nodes[1][old_property_key].should == 1
    inserter.created_nodes[1][new_property_key].should be_nil

    rule_inserter.node_added(3, {'_classname' => clazz.to_s, 'age' => 2})
    inserter.created_nodes[1][old_property_key].should == 1
    inserter.created_nodes[1][new_property_key].should == 1

    rule_inserter.node_added(3, {'_classname' => clazz.to_s, 'age' => 224})
    inserter.created_nodes[1][old_property_key].should == 2
    inserter.created_nodes[1][new_property_key].should == 1

  end

end