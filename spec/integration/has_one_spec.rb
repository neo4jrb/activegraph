require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::NodeMixin, "#has_one", :type => :transactional do
  context "unspecified outgoing relationship, e.g. has_one(:phone)" do
    before(:all) do
      @class = create_node_mixin do
        has_one(:phone)
      end
    end

    context "specified relationship: has_n(:phone).relationship(PhoneType)" do
      before(:all) do
        @phone_type_class = create_rel_mixin
        @person_class = create_node_mixin
        @person_class.has_one(:phone).relationship(@phone_type_class)
      end

      context "generated 'phone' method" do
        it "<< create Role Relationships" do
          person = @person_class.new
          person.phone = Neo4j::Node.new
          # then
          person.phone_rel.class.should == @phone_type_class
        end
      end
    end

    context "generated 'phone=' method" do
      it "creates a new outgoing relationship 'phone'" do
        person       = @class.new
        person.phone = Neo4j::Node.new
        person.rel?("phone", :outgoing).should be_true
      end

      it "deletes all old relationship before creating a new relationship" do
        person       = @class.new
        a            = Neo4j::Node.new
        person.phone = a
        a.rels.size.should == 1

        # when
        b            = Neo4j::Node.new
        person.phone = b

        # then
        a.rels.size.should == 0
        new_tx
        Neo4j::Node.load(b.neo_id).should == b # make sure the old node was not deleted - old bug
        person.outgoing(:phone).first.should == b
      end

    end

    context "generated 'phone' method" do
      it "returns the other node or nil if there is none" do
        person = @class.new
        person.phone.should be_nil
        a            = Neo4j::Node.new
        person.phone = a
        person.phone.should == a
      end
    end

    context "generated 'phone_rel' method" do
      it "return the relationship between the two nodes (or nil if none)" do
        person = @class.new
        person.phone_rel.should == nil
        a            = Neo4j::Node.new
        person.phone = a
        person.phone_rel.end_node.should == a
      end
    end

  end

  context "specified outgoing relationship: has_one(:phone).to(OtherClass)" do
    before(:all) do
      @other_class = create_node_mixin {}
      @class       = create_node_mixin {}
      @class.has_one(:phone).to(@other_class)
    end

    context "generated 'phone=' method" do
      it "creates a new outgoing relationship 'OtherClass#phone'" do
        person       = @class.new
        person.phone = Neo4j::Node.new
        person.rel?("#{@other_class}#phone", :outgoing).should be_true
      end
    end

    context "generated 'phone' method" do
      it "returns the outgoing relationship 'OtherClass#phone' or nil if none" do
        person = @class.new
        person.phone.should be_nil
        other = Neo4j::Node.new
        person.phone = other
        person.rel?("#{@other_class}#phone", :outgoing).should be_true
        person.phone.should == other
      end
    end

    context "generated 'phone_rel' method" do
      it "return the relationship between the two nodes (or nil if none)" do
        person = @class.new
        person.phone_rel.should == nil
        a            = Neo4j::Node.new
        person.phone = a
        person.phone_rel.end_node.should == a
      end
    end
  end


  context "unspecified incoming relationship: has_one(:user).from(:profile)" do
    before(:all) do
      @class = create_node_mixin do
        has_one(:user).from(:profile)
      end
    end

    context "generated 'user=' method" do
      it "creates a new incoming relationship 'profile'" do
        node      = @class.new
        node.user = Neo4j::Node.new
        node.rel?("profile", :incoming).should be_true
      end
    end

    context "generated 'user' method" do
      it "returns the incoming relationship 'profile' or nil if none" do
        node = @class.new
        node.user.should be_nil
        other = Neo4j::Node.new
        node.user = other
        node.user.should == other
      end
    end
  end


  context "specified incoming relationship: has_one(:user).from(User, :profile)" do
    before(:all) do
      @user  = create_node_mixin "User"
      @class = create_node_mixin "MyClass"
      @user.has_one(:profile).to(@class)
      @class.has_one(:user).from(@user, :profile)
    end

    context "generated 'user=' method" do
      it "creates a new incoming relationship 'MyClass#profile'" do
        node      = @class.new
        node.user = Neo4j::Node.new
        node.rel?("#{@class}#profile", :incoming).should be_true
      end
    end

    context "generated 'user' method" do
      it "returns the incoming relationship 'User#profile' or nil if none" do
        node = @class.new
        node.user.should be_nil
        other = Neo4j::Node.new
        node.user = other
        node.user.should == other
      end
    end
  end


  context "from a has_n relationship" do
    before(:all) do
      @movie_class = create_node_mixin "Movie"
      @director_class = create_node_mixin "Director"
      @director_class.has_n(:directed).to(@movie_class)
      @movie_class.has_one(:director).from(@director_class, :directed)
    end

    it "has_one/has_n: one-to-many, e.g. director --directed -*> movie" do
      lucas = @director_class.new :name => 'George Lucas'

      star_wars_4 = @movie_class.new :title => 'Star Wars Episode IV: A New Hope', :year => 1977
      star_wars_3 = @movie_class.new :title => "Star Wars Episode III: Revenge of the Sith", :year => 2005
      lucas.directed << star_wars_3 << star_wars_4

      # then
      lucas.directed.should include(star_wars_3, star_wars_4)
      lucas.outgoing("#{@movie_class}#directed").should include(star_wars_3, star_wars_4)
      star_wars_3.incoming("#{@movie_class}#directed").should include(lucas)
      star_wars_3.director.should == lucas
      star_wars_4.director.should == lucas
    end

  end
#  it "can add nodes to an incoming relationship" do
#    p1 = Person.new
#    p2 = Person.new
#    p3 = Person.new
#    p2.friend_by << p1
#    p1.friends << p3
#
#    p1.friends.size.should == 2
#    p1.friends.should include(p2, p3)
#    p2.friend_by.should include(p1)
#    p3.friend_by.should include(p1)
#  end
#
#  it "can navigate a incoming relationship (has_n(:employed_by).from(Company, :employees))" do
#    p1     = Person.new
#    p2     = Person.new
#
#    jayway = Company.new
#    jayway.employees << p1 << p2
#
#    google = Company.new
#    google.employees << p1
#
#    # then
#    p1.employed_by.size.should == 2
#    p2.employed_by.size.should == 1
#    p1.employed_by.should include(jayway, google)
#    p2.employed_by.should include(jayway)
#    jayway.employees.should include(p1, p2)
#    google.employees.should include(p1)
#  end
#

end
