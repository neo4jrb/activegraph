require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class FindableModel < Neo4j::Rails::Model
  property :name
  property :age, :type => Fixnum
  index :name
  index :age

  def to_s
    name
  end
end

describe "finders" do
	subject { FindableModel.create!(:name => "Test 1", :age => 4241) }
		
	before(:each) do
		@test_0 = FindableModel.create!(:name => "Test 0")    
		@test_2 = FindableModel.create!(:name => "Test 2")
		@test_3 = FindableModel.create!(:name => "Test 3", :age => 3)
		@test_4 = FindableModel.create!(:name => "Test 1")
	end

  context "index property with type Fixnum, :age, :type => Fixnum" do
    it "find_by_age(a fixnum) should work because age is declared as a Fixnum" do
      FindableModel.find_by_age(3).should == @test_3
    end
  end

  context "#close_lucene_connections" do
    it "sets the Thread.current[:neo4j_lucene_connection] to nil and close all lucene connections" do
      FindableModel.find('name: Test*')
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
		FindableModel.find.should be_a(FindableModel)
		FindableModel.find(:first).should be_a(FindableModel)
	end

  context "anomalous cases" do
    it "should return all when args normalises down to nothing" do
      subject.class.all(:conditions => {}).to_a.should == subject.class.all.to_a
      subject.class.first(:conditions => {}).should == subject.class.first
    end


    context ".find" do
      def nonexistant_id
        i       = rand(1000)
        all_ids = Neo4j.all_nodes.map(&:id)
        while (all_ids.include?(i))
          i = rand(1000)
        end
        i
      end

      def non_findable_model_allocated_ids
        Neo4j.all_nodes.select { |node| !node.is_a?(FindableModel) }.map(&:id)
      end

      it "should return nil when passed a non-existant id" do
        FindableModel.find(nonexistant_id).should be_nil
        FindableModel.find(nonexistant_id.to_s).should be_nil
      end

      it "should return an empty array when passed multiple non-existant ids" do
        FindableModel.find(nonexistant_id, nonexistant_id, nonexistant_id, nonexistant_id).should == []
        FindableModel.find(nonexistant_id.to_s, nonexistant_id.to_s, nonexistant_id.to_s, nonexistant_id.to_s).should == []
      end

      it "should return nil for ids allocated to other node types" do
        non_findable_model_allocated_ids.each do |i|
          FindableModel.find(i).should be_nil
          FindableModel.find(i.to_s).should be_nil
        end
      end

      it "should return nil for the id of the reference node" do
        FindableModel.find(0).should be_nil
        FindableModel.find("0").should be_nil
      end
    end
  end


  context ".find" do
    def nonexistant_id
      i       = rand(10000) + 1000000
      all_ids = FindableModel.all.map { |m| m.id.to_i }
      while (all_ids.include?(i))
        i = rand(10000) + 1000000
      end
      i
    end

    it "should return nil when passed a non-existant id" do
      FindableModel.find(nonexistant_id).should be_nil
    end

    it "should return an empty array when passed multiple non-existant ids" do
      FindableModel.find(nonexistant_id, nonexistant_id, nonexistant_id, nonexistant_id).should == []
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
      FindableModel.all('name: Test*').asc(:name).first.should == @test_0
    end

    it "#all(query).desc(field) should sort descending" do
      FindableModel.all('name: Test*').desc(:name).first.should == @test_3
    end

    it "#find(:all, query).asc(field) should sort ascending" do
      FindableModel.find(:all, 'name: Test*').asc(:name).first.should == @test_0
    end

    it "#first(:all, query).desc(field) should sort descending" do
      FindableModel.find(:all, 'name: Test*').desc(:name).first.should == @test_3
    end

	end

  context "pagination" do
    it "#paginate(:all, query, :per_page => , :page=>, :sort=>)" do
      it_should_be_sorted([0,1,2,3], FindableModel.paginate(:all, 'name: Test*', :page => 1, :per_page => 5, :sort => {:name => :asc}))
      it_should_be_sorted([0,1], FindableModel.paginate(:all, 'name: Test*', :page => 1, :per_page => 2, :sort => {:name => :asc}))
      it_should_be_sorted([2,3], FindableModel.paginate(:all, 'name: Test*', :page => 2, :per_page => 2, :sort => {:name => :asc}))      
      it_should_be_sorted([3,2,1,0], FindableModel.paginate(:all, 'name: Test*', :page => 1, :per_page => 5, :sort => {:name => :desc}))
    end

    it "#all(query).asc(field).paginate(:per_page => , :page=>)" do
      it_should_be_sorted([0,1,2], FindableModel.all('name: Test*').asc(:name).paginate(:page => 1, :per_page => 3))
      it_should_be_sorted([3], FindableModel.all('name: Test*').asc(:name).paginate(:page => 2, :per_page => 3))
    end

    it "#all.paginate(:per_page => , :page=>)" do
      res = FindableModel.all.paginate(:page => 1, :per_page => 5)
      res.current_page.should == 1
      res.total_entries.should == 4
      res.size.should == 4
      res.should include(@test_0, @test_2, @test_3, @test_4)
    end

  end

  def it_should_be_sorted(order, result)
    res = [*result].collect{|n| n.to_s}
    expectation = order.collect{|n| "Test #{n}"}
    expectation.reverse! if order == :desc
    res.should == expectation
  end
  
	context "for single records" do
		subject { @test_2 }

		# find by id
		it { should == FindableModel.find(subject.id) }
		it { should == FindableModel.find(subject.id.to_i) }
		it { should == FindableModel.find(:id => subject.id) }
		it { should == FindableModel.find(:id => subject.id.to_i) }
		it { should == FindableModel.find(:first, :id => subject.id) }
		it { should == FindableModel.find(:first, :id => subject.id.to_i) }
		it { should == FindableModel.find(:first, :conditions => { :id => subject.id }) }
		it { should == FindableModel.find(:first, :conditions => { :id => subject.id.to_i }) }

		it { should == FindableModel.find(:first, "name: \"Test 2\"") }
		it { should == FindableModel.find(:first, { :name => "Test 2" }) }
		it { should == FindableModel.find(:first, { :name => "Test 2" }, :sort => {:name => :desc}) }

		it { should == FindableModel.find(:first, :conditions => "name: \"Test 2\"") }
		it { should == FindableModel.find(:first, :conditions => { :name => "Test 2" }) }
		it { should == FindableModel.find(:first, :conditions => { :name => "Test 2" }, :sort => {:name => :desc}) }

		it { should == FindableModel.find(:conditions => "name: \"Test 2\"") }
		it { should == FindableModel.find(:conditions => { :name => "Test 2" }) }
    it { should == FindableModel.find(:conditions => "name: \"Test 2\"", :sort => {:name => :desc})}

		it { should == FindableModel.find(:name => "Test 2") }
		it { should == FindableModel.find("name: \"Test 2\"") }
    it { should == FindableModel.find("name: \"Test 2\"", :sort => {:name => :desc} ) }

		it { should == FindableModel.find_by_name("Test 2") }
	end

	context "for multiple records" do
		it "should be included" do
			it_should_be_included_in(FindableModel.find(:all))
			it_should_be_included_in(FindableModel.find(:all, :conditions => "name: \"Test 1\"") )
			it_should_be_included_in(FindableModel.find(:all, :conditions => { :name => "Test 1" }))
			it_should_be_included_in(FindableModel.all(:conditions => "name: \"Test 1\""))
			it_should_be_included_in(FindableModel.all(:conditions => { :name => "Test 1" }))
			it_should_be_included_in(FindableModel.find(:all, "name: \"Test 1\""))
			it_should_be_included_in(FindableModel.find(:all, :name => "Test 1"))
			it_should_be_included_in(FindableModel.all("name: \"Test 1\""))
			it_should_be_included_in(FindableModel.all(:name => "Test 1"))
			it_should_be_included_in(FindableModel.find(subject.id.to_i, @test_3.id.to_i, @test_4.id.to_i))
			it_should_be_included_in(FindableModel.all_by_name("Test 1"))
		end

		it "should have only one 'Test 1'" do
			FindableModel.all_by_name("Test 1").size.should == 1
		end
	end

	def it_should_be_included_in(array)
		array.should include(subject)
	end

	pending "A test for Neo4j::Rails::Model#last"
end
