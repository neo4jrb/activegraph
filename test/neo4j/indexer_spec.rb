$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'


include Neo4j


describe Indexer, " given Employee.salary in employed_by Company is indexed" do
  before(:all) do
    undefine_class :Employee, :Company
    start

    class Employee
      include Neo4j::NodeMixin
      property :salary
      has_one :employed_by
    end

    class Company
      include Neo4j::NodeMixin
      has_n(:employees).from(Employee, :employed_by)
    end

#    Indexer.clear_all_instances
    @employee_indexer = Indexer.instance Employee
    @company_indexer = Indexer.instance Company
    @employee_indexer.add_index_in_relationship_on_property(Company, 'employees', 'employed_by', 'salary', :employed_by)
  end

  after(:all) do
    Indexer.remove_instance Employee
    Indexer.remove_instance Company
  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  it "should update index when salary changes on one employee" do
    employee = Employee.new
    employee.salary = 10000

    company = Company.new
    employee.employed_by = company

    index = []
    @company_indexer.stub!(:lucene_index).and_return index

    # when
    @employee_indexer.on_property_changed(employee, 'salary')

    index.size.should == 1
    index[0][:id].should == company.neo_id
    index[0][:'employees.salary'].size.should == 1
    index[0][:'employees.salary'].should include(10000)
  end

  it "should update index when the employee relationship is created" do
    employee = Employee.new
    employee.salary = 10000

    company = Company.new
    employee.employed_by = company

    index = []
    @company_indexer.stub!(:lucene_index).and_return index

    # when
    @employee_indexer.on_relationship_created(employee, 'employed_by')

    index.size.should == 1
    index[0][:id].should == company.neo_id
    index[0][:'employees.salary'].size.should == 1
    index[0][:'employees.salary'].should include(10000)
  end

  it "should update index when the employee relationship is deleted" do
    employee = Employee.new
    employee.salary = 10000

    index = []
    @company_indexer.stub!(:lucene_index).and_return index

    # when
    @employee_indexer.on_relationship_created(employee, 'employed_by')

    index.size.should == 0
  end
end


describe Indexer, " given employees.salary is indexed on Company" do
  before(:all) do
    undefine_class :Employee, :Company
    class Employee
      include Neo4j::NodeMixin
      property :salary
    end

    class Company
      include Neo4j::NodeMixin
      has_n(:employees).to(Employee)
    end

    Indexer.remove_instance Employee
    Indexer.remove_instance Company
    @employee_indexer = Indexer.instance Employee
    @company_indexer = Indexer.instance Company
    @employee_indexer.add_index_in_relationship_on_property(Company, 'employees', 'employees', 'salary', "Employee#employees".to_sym)

  end

  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end


  it "should include each employees salary in the company index" do
    employee1 = Employee.new
    employee1.salary = 1
    employee2 = Employee.new
    employee2.salary = 2

    company = Company.new
    company.employees << employee1 << employee2

    index = []
    @company_indexer.stub!(:lucene_index).and_return index

    # when
    @company_indexer.index(company)

    index.size.should == 1
    index[0][:id].should == company.neo_id
    index[0][:'employees.salary'].size.should == 2
    index[0][:'employees.salary'].should include(1, 2)
  end

  it "should update index when salary changes on one employee" do
    employee = Employee.new
    employee.salary = 10000

    company = Company.new
    company.employees << employee

    index = []
    @company_indexer.stub!(:lucene_index).and_return index

    # when
    @employee_indexer.on_property_changed(employee, 'salary')

    index.size.should == 1
    index[0][:id].should == company.neo_id
    index[0][:'employees.salary'].size.should == 1
    index[0][:'employees.salary'].should include(10000)
  end

  it "should update index when the employee relationship is created" do
    employee = Employee.new
    employee.salary = 10000

    company = Company.new
    company.employees << employee

    index = []
    @company_indexer.stub!(:lucene_index).and_return index

    # when
    @employee_indexer.on_relationship_created(employee, 'Employee#employees')

    index.size.should == 1
    index[0][:id].should == company.neo_id
    index[0][:'employees.salary'].size.should == 1
    index[0][:'employees.salary'].should include(10000)
  end

  it "should update index when the employee relationship is deleted" do
    employee = Employee.new
    employee.salary = 10000

    index = []
    @company_indexer.stub!(:lucene_index).and_return index

    # when
    @employee_indexer.on_relationship_created(employee, 'employees')

    index.size.should == 0
  end

end



describe Indexer, " given friends.age is indexed on class Person" do
  before(:all) do
    undefine_class :Person
    class Person
      include Neo4j::NodeMixin
      property :age
      has_n :friends
    end
  end


  before(:each) do
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  def create_indexer
    Indexer.remove_instance Person
    indexer = Indexer.instance Person
    indexer.add_index_in_relationship_on_property(Person, 'friends', 'friends', 'age', :friends)
    indexer
  end

  it "should update index on one friend node index when its age property changes" do
    node1 = Person.new
    node2 = Person.new

    node1.friends << node2
    node1.age = 42

    index = []
    indexer = create_indexer
    indexer.stub!(:lucene_index).and_return index

    # when
    indexer.on_property_changed(node1, 'age')

    index.size.should == 1
    index[0][:id].should == node2.neo_id
    index[0][:'friends.age'].size.should == 1
    index[0][:'friends.age'].should include(42)
  end


  it "should update index on one friend which in turn has other friend nodes" do
    node1 = Person.new
    node2 = Person.new
    node3 = Person.new

    node1.friends << node2
    node2.friends << node3
    node1.age = 42
    node2.age = 43
    node3.age = 44

    index = []
    indexer = create_indexer
    indexer.stub!(:lucene_index).and_return index

    # when
    indexer.on_property_changed(node1, 'age')

    # find which index belongs to which node
    index.size.should == 1
    index_node2 = index[0]

    # then
    index_node2[:id].should == node2.neo_id
    index_node2[:'friends.age'].size.should == 2
    index_node2[:'friends.age'].should include(42, 44)
  end


  it "should update index on two friend nodes when its age property changes" do
    node1 = Person.new
    node2 = Person.new
    node3 = Person.new

    node1.friends << node2 << node3
    node1.age = 42
    node2.age = 43
    node3.age = 44

    index = []
    indexer = create_indexer
    indexer.stub!(:lucene_index).and_return index

    # when
    indexer.on_property_changed(node1, 'age')

    # find which index belongs to which node
    index.size.should == 2
    index_node2, index_node3 = index
    index_node2, index_node3 = index_node3, index_node2 unless index_node2[:id] == node2.neo_id

    # then
    index_node2[:id].should == node2.neo_id
    index_node2[:'friends.age'].size.should == 1
    index_node2[:'friends.age'].should include(42)

    index_node3[:id].should == node3.neo_id
    index_node2[:'friends.age'].size.should == 1
    index_node3[:'friends.age'].should include(42)
  end


  it "should not update index a node when its age property changes" do
    node = Person.new
    node.age = 42

    index = []
    indexer = create_indexer

    # should not index it
    indexer.should_not_receive(:lucene_index)

    # when
    indexer.on_property_changed(node, 'age')
  end
end

describe Indexer, " given property foo is indexed" do
  before(:each) do
    @node_class = mock('nodeClass')
    @node_class.should_receive(:root_class).any_number_of_times.and_return("Foo")
    @indexer = Indexer.instance @node_class
    @indexer.add_index_on_property('foo')
  end

  it "should update index if property foo is changed" do
    # given and then
    node = mock('node')
    node.should_receive(:class).any_number_of_times.and_return(@node_class)
    node.should_receive(:neo_id).and_return(42)
    node.should_receive(:foo).and_return("Hi")

    index = []
    @indexer.stub!(:lucene_index).and_return index

    # when
    @indexer.on_property_changed(node, 'foo')

    # then
    index.size.should == 1
    index[0][:id].should == 42
    index[0][:foo].should == "Hi"
  end

  it "should not update index if property bar is changed" do
    # given and then
    node = mock('node')

    # should not index it
    @indexer.should_not_receive(:lucene_index)

    # when
    @indexer.on_property_changed(node, 'bar')
  end


end

describe Indexer, " given index is defined in a subclass" do
  module IndexerExample
    class Base
      include Neo4j::NodeMixin

      def init_node
        time_now = Time.now

        self[:created] = time_now

      end

      property :created, :type => Time
      index :created
    end

    class Publication < Base
      property :title, :content
      index :title, :content
    end

    class Person < Base
      property :name, :uri

      has_n :publications

      index :name
    end

  end

  it "should not index a property that does not exist in the base class" do
    Neo4j::Transaction.run do
      person = IndexerExample::Person.new
      doc = IndexerExample::Publication.new

      person.name = 'Helio Miranda'

      doc.title = 'Test Document'
      doc.content = 'Test content'

      person.publications << doc
    end

  end
end















