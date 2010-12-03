require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class FindableModel < Neo4j::Rails::Model
	property :name
	index :name, :type => :exact
  
  def to_s
    name
  end
end

describe "finders" do
	subject { FindableModel.create!(:name => "Test 1") }
		
	before(:each) do
		@test_0 = FindableModel.create!(:name => "Test 0")    
		@test_2 = FindableModel.create!(:name => "Test 2")
		@test_3 = FindableModel.create!(:name => "Test 3")
		@test_4 = FindableModel.create!(:name => "Test 1")
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
      res = [*FindableModel.all.paginate(:page => 1, :per_page => 5)]
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
