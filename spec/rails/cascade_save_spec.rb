require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe "Neo4j::Rails Cascade delete with callbacks" do
#	subject { FindableModel.create!(:name => "Test 1", :age => 4241) }

  class CascadePerson < Neo4j::Rails::Model
    property :name
    has_n :friends
  end

  class CascadeGroup < Neo4j::Rails::Model
    has_n :people
  end

  class CascadeCompany < Neo4j::Rails::Model
    has_n(:groups)
    has_n :people
    has_one :leader

    before_save :cascade_add

    def cascade_add
      p1 = CascadePerson.create(:name => 'p1')

      self.people << p1

      p2 = CascadePerson.create(:name => 'p2')
      p1.friends << p2
    end
  end

  it "should allow to create new nodes in a rails callback" do
    c = CascadeCompany.create!

    c.people.size.should == 1
    c.people.first.friends.size.should == 1
#        first.should == c
  end
end

