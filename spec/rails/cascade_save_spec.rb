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

  #TODO: Consider moving the spec above under the example model below
  describe "example model" do
    let!(:person) do
      create_model
    end
    let!(:group) do
      create_model do
        has_n(:people)
      end
    end
    let!(:company) do
      create_model do
        has_n(:groups)
        has_one(:leader)
        def people
          groups.map{|g| g.people}.flatten
        end
      end
    end


    let(:brin)   { person.new }
    let(:larry)  { person.new }
    let(:google) { company.new(google_data) }

    subject { google }

    context "with modifying code in before_validation" do
      before do
        group_class = group
        company.before_validation do
          g = self.groups.first
          self.groups << (g = group_class.new) unless g
          g.people << leader if !g.people.include?(leader) && leader
        end
      end

      context "when saving" do
        subject { google.save; google.reload }

        context "with leader passed in" do
          let(:google_data) { {:leader => brin} }
          its(:valid?)      { should be_true }
          its(:people)      { should include brin }
        end

        context "with validation on a leader :)" do
          before            { company.validates(:leader, :presence=>true) }
          let(:google_data) { {:leader => nil} }
          its(:valid?)      { should be_false }
          its(:people)      { should be_empty }

          context "and validating before saving" do
            before            { google.valid? }
            let(:google_data) { {:leader => brin} }
            its(:persisted?)  { should be_true }
          end
        end
      end
    end

  end

end

