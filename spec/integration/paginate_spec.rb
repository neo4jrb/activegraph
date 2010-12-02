require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, "paginate", :type => :transactional do


  describe "#outgoing().paginate(..)" do
    before(:all) do
      @person_class = create_node_mixin do
        property :name
        has_n :friends

        def to_s
          "Person #{name}"
        end
      end
    end

    before(:each) do
      @person = @person_class.new :name => 'andreas'
      @friends = []
      20.times do |i|
        @friends << @person_class.new(:name => "#{i}")
      end
      @friends.each {|f| @person.friends << f}
    end

    it "should paginate outgoing nodes" do
      res = @person.outgoing(:friends).paginate(:page => 1, :per_page => 3)
      res.should include(@friends[0], @friends[1], @friends[2])
      res.should_not include(@friends[3])
      res.size.should == 3

      res = @person.outgoing(:friends).paginate(:page => 2, :per_page => 3)
      res.should include(@friends[3], @friends[4], @friends[5])
      res.should_not include(@friends[6], @friends[2])
      res.size.should == 3
    end
  end


  describe "find" do
    before(:all) do
      @clazz = create_node_mixin do
        property :days, :type => Fixnum
        index :days

        def to_s
          "Day #{days}"
        end
      end
    end

    before(:each) do
      @items = []
      20.times { |i| @items << @clazz.new(:days => i) }
      new_tx
    end

    it ":page => x, :per_page => y returns given range of nodes" do
      s = @clazz.paginate(:days => 0..55, :page => 1, :per_page => 5, :sort => {:days => :asc} )
      s.size.should == 5
      s[0].should == @items[0]
      s[4].should == @items[4]

      s = @clazz.paginate(:days => 0..55, :page => 2, :per_page => 5, :sort => {:days => :asc})
      s.size.should == 5

      s[0].should == @items[5]
      s[4].should == @items[9]
    end

    it "should allow sorting"

    it ":page => x, :per_page => y returns empty array if page does not exist" do
      s = @clazz.paginate(:days => 0..55, :page => 15, :per_page => 5)
      s.size.should == 0
    end


    it ":page => x, :per_page => y can return less then specified per_page when on the last page" do
      s = @clazz.paginate(:days => 0..55, :page => 2, :per_page => 15)
      s.size.should == 5
    end

  end


end
