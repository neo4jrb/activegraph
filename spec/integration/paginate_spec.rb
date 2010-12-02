require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, "paginate", :type => :transactional do

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
    20.times {|i| @items << @clazz.new(:days => i)}
    new_tx
  end

  it ":page => x, :per_page => y returns given range of nodes" do
    s = @clazz.paginate(:days => 0..55, :page => 1, :per_page => 5)
    s.size.should == 5
    s.should include(@items[0])
    s.should include(@items[4])

    s = @clazz.paginate(:days => 0..55, :page => 2, :per_page => 5)
    s.size.should == 5

    s.should include(@items[5])
    s.should include(@items[9])
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
