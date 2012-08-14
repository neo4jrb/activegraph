require 'spec_helper'


describe "finders", :type => :integration do

  let(:findable_class) do
    create_model do
      property :name, :index => :exact
      property :age, :type => Fixnum, :index => :exact
      property :status, :default => 'normal'
      validates_presence_of :name
      has_n(:items)
      has_n(:items_from).from(:items)
      def to_s
        name
      end
    end
  end

  subject { findable_class.create!(:name => "Test 1", :age => 4241) }

  before(:each) do
    @test_0 = findable_class.create!(:name => "Test 0")
    @test_2 = findable_class.create!(:name => "Test 2", :status => 'warning')
    @test_3 = findable_class.create!(:name => "Test 3", :age => 3)
    @test_4 = findable_class.create!(:name => "Test 1")

    @test_2.items << @test_3 << @test_4
    @test_2.save!
    @test_4.items << @test_0
    @test_4.save!
  end

  context "find without using a lucene index (use cypher)" do
    it "can find it with #all" do
      findable_class.all(:status => 'warning').first.should == @test_2
      findable_class.all(:status => 'normal').to_a.should =~ [@test_0, @test_3, @test_4]
    end

    it "can find it with #first" do
      findable_class.first(:status => 'warning').should == @test_2
    end

    it "can find it with #find" do
      findable_class.find(:status => 'warning').should == @test_2
    end

    it 'can find outgoing relationships' do
      findable_class.all(:items => @test_4).first.should == @test_2
      findable_class.first(:items => @test_4).should == @test_2
      findable_class.all(:items => @test_3).first.should == @test_2
      findable_class.first(:items => @test_3).should == @test_2
      findable_class.all(:items => @test_2).first.should be_nil
      findable_class.first(:items => @test_0).should == @test_4
    end

    it 'can find incoming relationships' do
      findable_class.all(:items_from => @test_2).to_a.should =~ [@test_3, @test_4]
    end

    it 'should not find things that should not be found' do
      findable_class.first(:status => 'oj').should be_nil
    end
  end

  context "index property with type Fixnum, :age, :type => Fixnum" do
    it "find_by_age(a fixnum) should work because age is declared as a Fixnum" do
      findable_class.find_by_age(3).should == @test_3
    end

    it "#find_by_age(a array)" do
      findable_class.find_by_age([3,2]).should == @test_3
    end
  end

  context "#close_lucene_connections" do
    it "sets the Thread.current[:neo4j_lucene_connection] to nil and close all lucene connections" do
      findable_class.find('name: Test*')
      Thread.current[:neo4j_lucene_connection].should_not be_nil
      Neo4j::Rails::Model.close_lucene_connections
      Thread.current[:neo4j_lucene_connection].should be_nil
    end

    it "close all lucene connections" do
      con_1 = mock "Connection1"
      con_1.should_receive(:close)
      con_2 = mock "Connection1"
      con_2.should_receive(:close)

      Thread.current[:neo4j_lucene_connection] = [con_1, con_2]
      Neo4j::Rails::Model.close_lucene_connections
    end

  end

  it "should be able to find something" do
    findable_class.find(:first).should be_a(findable_class)
  end

  context "anomalous cases" do
    it "should return all when args normalises down to nothing" do
      subject.class.all(:conditions => {}).to_a.should == subject.class.all.to_a
      subject.class.first(:conditions => {}).should == subject.class.first
    end


    context ".find" do
      def nonexistant_id
        i = rand(1000) + 1000000
        all_ids = Neo4j.all_nodes.map(&:id)
        while (all_ids.include?(i))
          i = rand(1000) + 1000000
        end
        i
      end

      def non_findable_model_allocated_ids
        Neo4j.all_nodes.select { |node| !node.is_a?(findable_class) }.map(&:id)
      end

      it "should return nil when passed a negative id" do
        findable_class.find(-99).should be_nil
      end

      it "should raise an exception when trying to find related nodes with a string" do
        lambda{findable_class.new.items("bla")}.should raise_error
        lambda{findable_class.new.items.all("bla")}.should raise_error
      end

      it "should return nil when passed " do
        findable_class.find(-99).should be_nil
      end

      it "should return nil when passed a non-existant id" do
        findable_class.find(nonexistant_id).should be_nil
        findable_class.find(nonexistant_id.to_s).should be_nil
      end

      it "should return an empty array when passed multiple non-existant ids" do
        ids = [nonexistant_id, nonexistant_id, nonexistant_id, nonexistant_id]
        all = findable_class.find(*ids)
        all.each { |x| puts "found1: #{x.id}/#{x.class} for #{ids.join(', ')}" }

        ids2 = [nonexistant_id, nonexistant_id, nonexistant_id, nonexistant_id]
        all2 = findable_class.find(*ids2)
        all2.each { |x| puts "found2: #{x.id}/#{x.class} for #{ids2.join(', ')}" }

        all.should be_empty
        all2.should be_empty

        #findable_class.find(nonexistant_id, nonexistant_id, nonexistant_id, nonexistant_id).should == []
        #findable_class.find(nonexistant_id.to_s, nonexistant_id.to_s, nonexistant_id.to_s, nonexistant_id.to_s).should == []
      end

      it "should return nil for ids allocated to other node types" do
        non_findable_model_allocated_ids.each do |i|
          findable_class.find(i).should be_nil
          findable_class.find(i.to_s).should be_nil
        end
      end

      it "should return nil for the id of the reference node" do
        findable_class.find(0).should be_nil
        findable_class.find("0").should be_nil
      end

      it "should return nil if id is nil" do
        findable_class.find(nil).should be_nil
      end

      it "should return nil if no args are given" do
        findable_class.find.should be_nil
      end
    end
  end

  context ".find" do
    def nonexistant_id
      i = rand(10000) + 1000000
      all_ids = findable_class.all.map { |m| m.id.to_i }
      while (all_ids.include?(i))
        i = rand(10000) + 1000000
      end
      i
    end

    it "should return nil when passed a non-existant id" do
      findable_class.find(nonexistant_id).should be_nil
    end

    it "should return an empty array when passed multiple non-existant ids" do
      findable_class.find(nonexistant_id, nonexistant_id, nonexistant_id, nonexistant_id).should == []
    end

    context "with threadlocal_ref_node" do
      let(:ref_1) { Neo4j::Rails::Model.create!(:name => "Ref1") }
      let(:ref_2) { Neo4j::Rails::Model.create!(:name => "Ref2") }

      before(:each) do
        Neo4j.threadlocal_ref_node = ref_1
        @node_from_ref_1 = findable_class.create!(:name => 'foo')
      end

      after(:each) do
        Neo4j.threadlocal_ref_node = nil
      end

      context "when node reachable from ref node" do
        it "should return node" do
          Neo4j.threadlocal_ref_node = ref_1

          findable_class.find(@node_from_ref_1.id).should == @node_from_ref_1
        end
      end

      context "when node not reachable from ref node" do
        it "should return nil" do
          Neo4j.threadlocal_ref_node = ref_2

          findable_class.find(@node_from_ref_1.id).should be_nil
        end
      end
    end
  end

  describe ".find!" do
    context "when the node by given id exists" do
      it "should return the node" do
        findable_class.find!(@test_0.id).should == @test_0
      end
    end

    context "for non existant node id" do
      subject { lambda { findable_class.find!(nonexistant_id = 99999) } }

      it { should raise_error Neo4j::Rails::RecordNotFoundError }
    end
  end

  describe ".find_or_create_by" do
    context "when the node is found" do
      let!(:node) do
        findable_class.create!(:name => "Foo", :ssn => "333-22-1111")
      end

      it "returns the node" do
        findable_class.find_or_create_by(:name => "Foo").should == node
      end
    end

    context "when the node is not found" do
      context "when not providing a block" do
        let!(:node) do
          findable_class.find_or_create_by(:name => "Bar", :age => "22")
        end

        it "creates a persisted node" do
          node.should be_persisted
        end

        it "sets the attributes" do
          node.name.should == "Bar"
          node.age.should == 22
        end
      end

      context "when providing a block" do
        let!(:node) do
          findable_class.find_or_create_by(:name => "Bar") do |node|
            node.age = 22
          end
        end

        it "creates a persisted node" do
          node.should be_persisted
        end

        it "sets the attributes" do
          node.name.should == "Bar"
        end

        it "calls the block" do
          node.age.should == 22
        end
      end

      context "when node is invalid" do
        let!(:node) do
          findable_class.find_or_create_by(:age => 22, :name => nil)
        end

        it "node is not persisted" do
          node.should_not be_persisted
        end

        it "node is invalid" do
          node.should be_invalid
        end
      end
    end
  end

  describe ".find_or_create_by!" do
    context "when the node is found" do
      let!(:node) do
        findable_class.create!(:name => "Foo", :ssn => "333-22-1111")
      end

      it "returns the node" do
        findable_class.find_or_create_by!(:name => "Foo").should == node
      end
    end

    context "when the node is not found" do
      context "when node is invalid" do
        subject do
          lambda { findable_class.find_or_create_by!(:age => 22, :name => nil) }
        end

        it { should raise_error Neo4j::Rails::Persistence::RecordInvalidError }
      end
    end
  end

  describe ".find_or_initialize_by" do
    context "when the node is found" do
      let!(:node) do
        findable_class.create!(:name => "Foo")
      end

      it "returns the node" do
        findable_class.find_or_initialize_by(:name => "Foo").should == node
      end
    end

    context "when the node is not found" do
      context "when not providing a block" do
        let!(:node) do
          findable_class.find_or_initialize_by(:name => "Bar", :age => 22)
        end

        it "creates a new node" do
          node.should be_new
        end

        it "sets the attributes" do
          node.name.should == "Bar"
          node.age.should == 22
        end
      end

      context "when providing a block" do
        let!(:node) do
          findable_class.find_or_initialize_by(:name => "Bar") do |node|
            node.age = 22
          end
        end

        it "creates a new node" do
          node.should be_new
        end

        it "sets the attributes" do
          node.name.should == "Bar"
        end

        it "calls the block" do
          node.age.should == 22
        end
      end
    end
  end

  context "query, :sort => {:field => :asc/:desc}" do

    it ":sort => {:name => :asc} should sort by ascending" do
      subject.class.all(:conditions => 'name: Test*', :sort => {:name => :asc}).first.should == @test_0
      subject.class.all('name: Test*', :sort => {:name => :asc}).first.should == @test_0
      subject.class.first(:conditions => 'name: Test*', :sort => {:name => :asc}).should == @test_0
      subject.class.first('name: Test*', :sort => {:name => :asc}).should == @test_0
      subject.class.find('name: Test*', :sort => {:name => :asc}).should == @test_0
    end

    it ":sort => {:name => :desc}, should sort by descending" do
      subject.class.all(:conditions => 'name: Test*', :sort => {:name => :desc}).first.should == @test_3
      subject.class.all('name: Test*', :sort => {:name => :desc}).first.should == @test_3
      subject.class.first(:conditions => 'name: Test*', :sort => {:name => :desc}).should == @test_3
      subject.class.first('name: Test*', :sort => {:name => :desc}).should == @test_3
      subject.class.find('name: Test*', :sort => {:name => :desc}).should == @test_3
    end

    it "#all(query).asc(field) should sort ascending" do
      findable_class.all('name: Test*').asc(:name).first.should == @test_0
    end

    it "#all(query).desc(field) should sort descending" do
      findable_class.all('name: Test*').desc(:name).first.should == @test_3
    end

    it "#find(:all, query).asc(field) should sort ascending" do
      findable_class.find(:all, 'name: Test*').asc(:name).first.should == @test_0
    end

    it "#first(:all, query).desc(field) should sort descending" do
      findable_class.find(:all, 'name: Test*').desc(:name).first.should == @test_3
    end

  end

  context "for single records" do
    subject { @test_2 }

    # find by id
    it { should == findable_class.find(subject.id) }
    it { should == findable_class.find(subject.id.to_i) }
    it { should == findable_class.find(:id => subject.id) }
    it { should == findable_class.find(:id => subject.id.to_i) }
    it { should == findable_class.find(:first, :id => subject.id) }
    it { should == findable_class.find(:first, :id => subject.id.to_i) }
    it { should == findable_class.find(:first, :conditions => {:id => subject.id}) }
    it { should == findable_class.find(:first, :conditions => {:id => subject.id.to_i}) }

    it { should == findable_class.find(:first, "name: \"Test 2\"") }
    it { should == findable_class.find(:first, {:name => "Test 2"}) }
    it { should == findable_class.find(:first, {:name => "Test 2"}, :sort => {:name => :desc}) }

    it { should == findable_class.find(:first, :conditions => "name: \"Test 2\"") }
    it { should == findable_class.find(:first, :conditions => {:name => "Test 2"}) }
    it { should == findable_class.find(:first, :conditions => {:name => "Test 2"}, :sort => {:name => :desc}) }

    it { should == findable_class.find(:conditions => "name: \"Test 2\"") }
    it { should == findable_class.find(:conditions => {:name => "Test 2"}) }
    it { should == findable_class.find(:conditions => "name: \"Test 2\"", :sort => {:name => :desc}) }

    it { should == findable_class.find(:name => "Test 2") }
    it { should == findable_class.find("name: \"Test 2\"") }
    it { should == findable_class.find("name: \"Test 2\"", :sort => {:name => :desc}) }

    it { should == findable_class.find_by_name("Test 2") }
  end

  context "for multiple records" do
    it "should be included" do
      it_should_be_included_in(findable_class.find(:all))
      it_should_be_included_in(findable_class.find(:all, :conditions => "name: \"Test 1\""))
      it_should_be_included_in(findable_class.find(:all, :conditions => {:name => "Test 1"}))
      it_should_be_included_in(findable_class.all(:conditions => "name: \"Test 1\""))
      it_should_be_included_in(findable_class.all(:conditions => {:name => "Test 1"}))
      it_should_be_included_in(findable_class.find(:all, "name: \"Test 1\""))
      it_should_be_included_in(findable_class.find(:all, :name => "Test 1"))
      it_should_be_included_in(findable_class.all("name: \"Test 1\""))
      it_should_be_included_in(findable_class.all(:name => "Test 1"))
      it_should_be_included_in(findable_class.find(subject.id.to_i, @test_3.id.to_i, @test_4.id.to_i))
      it_should_be_included_in(findable_class.all_by_name("Test 1"))
    end

    it "should have only one 'Test 1'" do
      findable_class.all_by_name("Test 1").size.should == 1
    end
  end

  context "queries scoped by reference node" do
    class ReferenceNode < Neo4j::Rails::Model
      property :name, :index => :exact
    end

    class FindableModel < Neo4j::Rails::Model
      property :name, :index => :exact
      property :age, :type => Fixnum, :index => :exact
      validates_presence_of :name

      def to_s
        name
      end
    end

    after(:each) do
      Neo4j.threadlocal_ref_node = nil
    end

    it "should return records scoped to a reference node" do
      Neo4j.threadlocal_ref_node = ReferenceNode.create(:name => "Ref1")
      model = FindableModel.create!(:name => "Test 10")
      FindableModel.find("name: \"Test 10\"").should == model
    end

    it "should not return records attached to another reference node" do
      ref1 = ReferenceNode.create(:name => "Ref1")
      ref2 = ReferenceNode.create(:name => "Ref2")
      Neo4j.threadlocal_ref_node = ref1
      FindableModel.index_name_for_type(:exact).should == "Ref1_FindableModel_exact"
      FindableModel.create!(:name => "Test 10")
      Neo4j.threadlocal_ref_node = ref2
      FindableModel.index_name_for_type(:exact).should == "Ref2_FindableModel_exact"
      FindableModel.find("name: \"Test 10\"").should be_nil
    end
  end

  def it_should_be_included_in(array)
    array.should include(subject)
  end

end
