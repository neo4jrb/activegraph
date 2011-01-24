require File.join(File.dirname(__FILE__), 'spec_helper')


describe Neo4j::NodeMixin, "paginate", :type => :transactional do


  describe "traversing nodes" do
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

    context "@person.outgoing(:friends).paginate(:page => 1, ..)" do
      subject { @person.outgoing(:friends).paginate(:page => 1, :per_page => 3) }

      it "includes page 1 and not page 2 nodes" do
        should include(@friends[0], @friends[1], @friends[2])
        should_not include(@friends[3])
        subject.size.should == 3
      end

      it "set current_page to 1" do
        subject.current_page.should == 1
      end

      it "sets total_entries" do
        subject.total_entries.should == 20
      end

    end

    context "@person.outgoing(:friends).paginate(:page => 2, ..)" do
      subject { @person.outgoing(:friends).paginate(:page => 2, :per_page => 3) }

      it "includes page 2 and not page 1 nodes" do
        should include(@friends[3], @friends[4], @friends[5])
        subject.size.should == 3
      end

      it "set current_page to 2" do
        subject.current_page.should == 2
      end

      it "sets total_entries" do
        subject.total_entries.should == 20
      end
    end


    it "@person.friends.paginate" do
      res = @person.friends.paginate(:page => 1, :per_page => 3)
      res.should include(@friends[0], @friends[1], @friends[2])
      res.should_not include(@friends[3])
      res.size.should == 3

      res = @person.friends.paginate(:page => 2, :per_page => 3)
      res.should include(@friends[3], @friends[4], @friends[5])
      res.should_not include(@friends[6], @friends[2])
      res.size.should == 3
    end
  end


  describe "has_list" do
    before(:all) do
      @person_class = create_node_mixin do
        property :name
        has_list :friends

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

    it "@person.friends.paginate" do
      res = @person.friends.paginate(:page => 1, :per_page => 3)
      res.should include(@friends[0], @friends[1], @friends[2])
      res.should_not include(@friends[3])
      res.size.should == 3

      res.total_entries.should == 20

      res = @person.friends.paginate(:page => 2, :per_page => 3)
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

    it "#paginate(query, :page => x, :per_page => y) returns given range of nodes" do
      s = @clazz.paginate(:days => 0..55, :page => 1, :per_page => 5, :sort => {:days => :asc} )
      s.size.should == 5
      s[0].should == @items[0]
      s[4].should == @items[4]

      s = @clazz.paginate(:days => 0..55, :page => 2, :per_page => 5, :sort => {:days => :asc})
      s.size.should == 5

      s[0].should == @items[5]
      s[4].should == @items[9]
    end

    it "#paginate(:conditions => query, :page => x, :per_page => y) returns given range of nodes" do
      s = @clazz.paginate(:conditions => {:days => 0..55}, :page => 1, :per_page => 5, :sort => {:days => :asc} )
      s.size.should == 5
      s[0].should == @items[0]
      s[4].should == @items[4]

      s = @clazz.paginate(:conditions => {:days => 0..55}, :page => 2, :per_page => 5, :sort => {:days => :asc})
      s.size.should == 5

      s[0].should == @items[5]
      s[4].should == @items[9]
    end

    it "#paginate(:page => x, :per_page => y) returns empty array if page does not exist" do
      s = @clazz.paginate(:days => 0..55, :page => 15, :per_page => 5)
      s.size.should == 0
    end


    it "#paginate(:page => x, :per_page => y) can return less then specified per_page when on the last page" do
      s = @clazz.paginate(:days => 0..55, :page => 2, :per_page => 15)
      s.size.should == 5
    end

    it "#paginate(:page => x, :per_page => y) return all if per_page is bigger then total size" do
      s = @clazz.paginate(:days => 0..55, :page => 1, :per_page => 150)
      s.size.should == 20
    end

    it "find(query).asc(field).paginate(:page=>x, :per_page=>y) returns given range of nodes" do
      s = @clazz.find(:days => 0..55).asc(:days).paginate(:page => 2, :per_page => 5)
      s.size.should == 5

      s[0].should == @items[5]
      s[4].should == @items[9]
    end

  end


end
