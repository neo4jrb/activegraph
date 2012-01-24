require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Batch::Inserter do
  before(:each) do
    # It is not allowed to run the neo4j the same time as doing batch inserter
    Neo4j.shutdown
    rm_db_storage
    @storage_path = File.expand_path(File.join(Dir.tmpdir, 'neo4j-batch-inserter'))
    FileUtils.rm_rf @storage_path
    Neo4j.threadlocal_ref_node = nil    
  end

  after(:each) do
    @inserter && @inserter.shutdown
  end

  # Nodes/Properties and Relationships
  context "#new(path, config)" do

    it "ot started" do
      Neo4j.running?.should be_false
    end

    it "raise an exception if neo4j is running using the same storage path" do
      Neo4j.start
      lambda do
        @inserter = Neo4j::Batch::Inserter.new
      end.should raise_error
    end

    it "allows running neo4j at the same time as creating the batch inserter if it does not use the same storage path" do
      Neo4j.start
      lambda do
        @inserter = Neo4j::Batch::Inserter.new(@storage_path)
      end.should_not raise_error
    end

    it "#running is true if creating a inserter" do
      @inserter = Neo4j::Batch::Inserter.new(@storage_path)
      @inserter.should be_running
#      File.exist?(@storage_path).should be_true
    end

    it "#running should be false after shutdown" do
      @inserter = Neo4j::Batch::Inserter.new(@storage_path)
      @inserter.shutdown
      @inserter.should_not be_running

#      File.exist?(@storage_path).should be_true
    end

    it "creates the folder at storage_path when it starts" do
      File.exist?(@storage_path).should be_false
      @inserter = Neo4j::Batch::Inserter.new(@storage_path)
      File.exist?(@storage_path).should be_true
    end

    it "uses default Neo4j.storage_path if not provided one" do
      @inserter = Neo4j::Batch::Inserter.new
      File.exist?(Neo4j.config.storage_path).should be_true
    end
  end

  context "#create_node() #=> id" do
    before(:each) do
      @inserter = Neo4j::Batch::Inserter.new
      @id       = @inserter.create_node
    end

    it "#node_exist?(id) == true" do
      @inserter.node_exist?(@id).should be_true
    end

    it "#node_props(id) == {}" do
      @inserter.node_props(@id).should be_empty
    end

    it "#set_node_props(id, props)" do
      @inserter.set_node_props(@id, 'name' => 'andreas')
      hash = @inserter.node_props(@id)
      hash['name'].should == 'andreas'
      hash.size.should == 1
    end
  end

  context "#create_node(hash)" do
    before(:each) do
      @inserter = Neo4j::Batch::Inserter.new
      @id = @inserter.create_node('name' => 'kalle123', :age => 42)
    end

    it "creates a node with given properties" do
      @inserter.node_exist?(@id).should be_true
      hash = @inserter.node_props(@id)
      hash['name'].should == 'kalle123'
      hash['age'].should == 42
      hash.size.should == 2
      @inserter.shutdown
      Neo4j.all_nodes.collect { |n| n[:name] }.should include('kalle123')
      Neo4j.all_nodes.collect { |n| n[:age] }.should include(42)
    end

    it "#set_node_props(id, props), overwrites old props" do
      @inserter.set_node_props(@id, 'name' => 'andreas')
      hash = @inserter.node_props(@id)
      hash['name'].should == 'andreas'
      hash.size.should == 1
      @inserter.shutdown
      Neo4j.all_nodes.collect { |n| n[:name] }.should include('andreas')
      Neo4j.all_nodes.collect { |n| n[:age] }.should_not include(42)
    end

  end

  context "#create_node(hash, PersonNode)" do
    before(:each) do
      @clazz = create_node_mixin
      @old_storage_path = Neo4j::Config[:storage_path]
      Neo4j::Config[:storage_path] = @storage_path
      @inserter = Neo4j::Batch::Inserter.new
      @person_1_id = @inserter.create_node({'name' => 'kalle123', 'age' => 42}, @clazz)
    end

    after(:each) do
      Neo4j::Config[:storage_path] = @old_storage_path
    end

    it "sets the _classname property to PersonNode" do
      @inserter.node_props(@person_1_id)['_classname'].should == @clazz.to_s
    end

    it "can create a relationship between two created PersonNodes" do
      node2 = @inserter.create_node({'name' => 'kalle123', 'age' => 42}, @clazz)
      rel = @inserter.create_rel('friends', @person_1_id, node2)
      rel.should be_a(Fixnum)
    end

    it "can also create a relationship between an already existing node", :type => :slow do
      # first create a node using transactions
      @inserter.shutdown
      Neo4j.start
      new_tx
      person_2 = @clazz.new
      person_2_id = person_2.neo_id
      finish_tx
      Neo4j.shutdown

      # create a relationship using batch insert
      @inserter = Neo4j::Batch::Inserter.new
      @inserter.create_rel('friends1', person_2_id, @person_1_id)
      @inserter.create_rel('friends2', @person_1_id, person_2_id)
      @inserter.shutdown

      # make sure this relationships exists
      Neo4j.start
      p2 = Neo4j::Node.load(person_2_id)
      p2.class.should == @clazz
      p2.outgoing(:friends1).size.should == 1
      p2.outgoing(:friends1).first.neo_id.should == @person_1_id

      p1 = Neo4j::Node.load(@person_1_id)
      p1.class.should == @clazz
      p1.outgoing(:friends2).size.should == 1
      p1.outgoing(:friends2).first.neo_id.should == person_2_id
      Neo4j.shutdown
    end
  end
  
  context "#ref_node" do
    it "returns the reference node" do
      @inserter = Neo4j::Batch::Inserter.new
      ref_node = @inserter.ref_node
      @inserter.node_exist?(ref_node).should be_true
    end
  end

  context "#create_rel(:friend, node_a, node_b)" do
    before(:each) do
      @inserter = Neo4j::Batch::Inserter.new
      @node_a = @inserter.create_node
      @node_b = @inserter.create_node
      @rel_id = @inserter.create_rel(:friend, @node_a, @node_b)
    end

    it "#rels(node_a).size == 1" do
      @inserter.rels(@node_a).size.should == 1
    end

    
    it "#rels(node_a).first returns a simple relationship responding to get_start_node, get_end_node and get_type"  do
      rel = @inserter.rels(@node_a).first
      rel.get_start_node.should == @node_a
      rel.start_node.should == @node_a
      rel.get_end_node.should == @node_b
      rel.get_type.name == 'friend'
    end

    it "#set_rel_props(rel_id, props) sets relationship properties" do
      @inserter.set_rel_props(@rel_id, 'name' => 'hoho')
      @inserter.rel_props(@rel_id).size.should == 1
      @inserter.rel_props(@rel_id)['name'].should == 'hoho'
    end
  end

  context "#create_rel(:friend, node_a, node_b, hash)" do
    before(:each) do
      @inserter = Neo4j::Batch::Inserter.new
      @node_a = @inserter.create_node
      @node_b = @inserter.create_node
      @rel_id = @inserter.create_rel(:friend, @node_a, @node_b, 'name' => 'aaa', :age => 4242)
    end

    it "#rel_props(id) should include properties" do
      hash = @inserter.rel_props(@rel_id)
      hash.size.should == 2
      hash['name'].should == 'aaa'
      hash['age'].should == 4242
    end

    it "returns a fixnum id of the created relationship." do
      @rel_id.class.should == Fixnum
    end
  end

  context "rules" do
    before(:each) do
      @inserter = Neo4j::Batch::Inserter.new
    end
    
    class MyBatchInsertedClass
      include Neo4j::NodeMixin
      rule(:all)
      rule(:young, :functions => Neo4j::Rule::Functions::Count.new) {|node| node[:age] && node[:age] <= 10}
    end

    it "can count nodes" do
      # not declared rule
      @clazz = create_node_mixin
      @inserter.create_node({'age' => 2}, @clazz)

      # declared rule
      node_a = @inserter.create_node({'age' => 2}, MyBatchInsertedClass)
      node_b = @inserter.create_node({}, MyBatchInsertedClass)
      node_c = @inserter.create_node({'age' => 3}, MyBatchInsertedClass)
      node_d = @inserter.create_node({'age' => 300}, MyBatchInsertedClass)
      @inserter.shutdown
      MyBatchInsertedClass.all.size.should == 4
      MyBatchInsertedClass.all.collect{|n| n.neo_id}.should include(node_a, node_b, node_c, node_d)
      MyBatchInsertedClass.young.collect{|n| n.neo_id}.should include(node_a, node_c)
      MyBatchInsertedClass.count(:young).should == 2
      MyBatchInsertedClass.young.to_a.size.should == 2
      @clazz.should_not respond_to(:all)
    end
  end

end
