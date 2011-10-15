require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, "find", :type => :transactional do

  context "with type conversion: property :year, :type => Fixnum" do
    before(:all) do
      @clazz = create_node_mixin do
        property :year, :type => Fixnum
        property :month, :day, :type => Fixnum
        index :year
        index :month, :day
        def to_s
          "Year #{year}"
        end
      end
    end

    before(:each) do
      @x49 = @clazz.new(:year => 49, :month => 1, :day => 11)
      @x50 = @clazz.new(:year => 50, :month => 2, :day => 12)
      @x51 = @clazz.new(:year => 51, :month => 3, :day => 13)
      @x52 = @clazz.new(:year => 52, :month => 4, :day => 14)
      @x53 = @clazz.new(:year => 53, :month => 5, :day => 15)
      new_tx
    end


    it "find(:year => 50) does work because year is declared as a Fixnum" do
      res = @clazz.find(:year=>50) #.between(45,45,true,true)
      res.first.should == @x50
    end

    it "find(:year => 50..52) returns all integer between 50 and 52" do
      res = [*@clazz.find(:year=> 50..52)]
      res.should_not include(@x49,@x53)
      res.should include(@x50,@x51,@x52)
    end

    it "find(:year => 50...52) returns all integer between 50 and 51" do
      res = [*@clazz.find(:year=> 50...52)]
      res.should include(@x50,@x51)
      res.should_not include(@x49,@x52,@x53)
    end

    it "find(:month=> 2..5, :day => 11...14) finds nodes matching both conditions" do
      res = [*@clazz.find(:month=> 2..5, :day => 11...14)]
      res.should include(@x50,@x51)
      res.should_not include(@x49,@x52,@x53)
    end

  end


  context "on arrays of properties" do
    before(:all) do
      @clazz = create_node_mixin do
        property :items
        index :items
      end
    end

    it "should index all values in the array" do
      node = @clazz.new :items => %w[hej hopp oj]
      new_tx
      result = @clazz.find('items: hej')
      result.size.should == 1
      result.should include(node)

      result = @clazz.find('items: hopp')
      result.size.should == 1
      result.should include(node)

      result = @clazz.find('items: oj')
      result.size.should == 1
      result.should include(node)
    end

    it "when an item in the array is removed it should not be found" do
      node = @clazz.new :items => %w[hej hopp oj]
      new_tx
      #node.items.delete('hopp') # does not work
      node.items = %w[hej oj]
      new_tx

      result = @clazz.find('items: hej')
      result.size.should == 1
      result.should include(node)

      result = @clazz.find('items: hopp')
      result.size.should == 0

      result = @clazz.find('items: oj')
      result.size.should == 1
      result.should include(node)
    end


  end


  context "hash queries, find(hash)" do
    before(:each) do
      @bike = Vehicle.new(:name => 'bike', :wheels => 2)
      @car = Vehicle.new(:name => 'car', :wheels => 4)
      @old_bike = Vehicle.new(:name => 'old bike', :wheels => 2)
      new_tx
    end

    it "find(:name => 'bike', :wheels => 2)" do
      result = [*Vehicle.find(:name => 'bike', :wheels => 2)]
      result.size.should == 1
      result.should include(@bike)
    end

    it "find(:conditions => {:name => 'bike', :wheels => 2})" do
      result = [*Vehicle.find(:conditions => {:name => 'bike', :wheels => 2})]
      result.size.should == 1
      result.should include(@bike)
    end

    it "find({}) should return nothing" do
      result = [*Vehicle.find({})]
      result.size.should == 0
    end

    it "find(:name => 'bike').and(:wheels => 2) should return same thing as find(:name => 'bike', :wheels => 2)" do
      result = [*Vehicle.find(:name => 'bike').and(:wheels => 2)]
      result.size.should == 1
      result.should include(@bike)
    end

  end

  context "range queries, index :name, :type => String" do
    before(:all) do
      @clazz = create_node_mixin do
        property :name, :type => String
        index :name
      end
    end

    before(:each) do
      @bike = @clazz.new(:name => 'bike')
      @car = @clazz.new(:name => 'car')
      @old_bike = @clazz.new(:name => 'old bike')
      new_tx
    end

    it "find(:name).between('f', 'q')" do
      result = [*@clazz.find(:name).between('f', 'q')]
      result.should include(@old_bike)
      result.size.should == 1
    end

    it "find(:name).between(5.0, 10.0).asc(:name)" do
      result = [*@clazz.find(:name).between('a', 'z').asc(:name)]
      result.size.should == 3
      result.should == [@bike, @car, @old_bike]
    end

    it "find(:name).between(5.0, 10.0).desc(:name)" do
      result = [*@clazz.find(:name).between('a', 'z').desc(:name)]
      result.size.should == 3
      result.should == [@old_bike, @car, @bike]
    end
  end

  context "range queries, index :weight; property :weight, :type => Float" do
    before(:all) do
      @clazz = create_node_mixin do
        property :weight, :type => Float
        index :weight
        index :name
      end
    end

    before(:each) do
      @bike = @clazz.new(:name => 'bike', :weight => 9.23)
      @car = @clazz.new(:name => 'car', :weight => 1042.99)
      @old_bike = @clazz.new(:name => 'old bike', :weight => 21.42)
      new_tx
    end

    it "find(:weight).between(5.0, 10.0)" do
      result = [*@clazz.find(:weight).between(5.0, 10.0)]
      result.should include(@bike)
      result.size.should == 1
    end

    it "find(:weight).between(5.0, 10.0).asc(:weight)" do
      result = [*@clazz.find(:weight).between(1.0, 10000.0).asc(:weight)]
      result.should == [@bike, @old_bike, @car]
      result.size.should == 3
    end

    it "find(:weight).between(5.0, 10.0).desc(:weight)" do
      result = [*@clazz.find(:weight).between(1.0, 10000.0).desc(:weight)]
      result.should == [@car, @old_bike, @bike]
      result.size.should == 3
    end

    it "find(:weight).between(5.0, 100000.0).and(:name).between('a', 'd')" do
      result = [*@clazz.find(:weight).between(5.0, 100000.0).and(:name).between('a', 'd')]
      result.size.should == 2
      result.should include(@bike, @car)
    end

    it "find('weight:[5.0 TO 10.0]')" do
      pending "Does not work"
      result = [*@clazz.find('weight:[5.0 TO 10.0]')]
      result.size.should == 1
      result.should include(@bike)
    end
  end

  context "range queries, index :items; property :items, :type => Fixnum" do
    before(:all) do
      @clazz = create_node_mixin do
        property :items, :type => Fixnum
        index :items
        index :name
      end
    end

    before(:each) do
      @bike = @clazz.new(:name => 'bike', :items => 9)
      @car = @clazz.new(:name => 'car', :items => 1042)
      @old_bike = @clazz.new(:name => 'old bike', :items => 21)
      new_tx
    end

    it "find(:items).between(5, 10)" do
      @bike.items.should == 9
      @bike.items.class.should == Fixnum
      @bike._java_node.get_property('items').class.should == Fixnum
      result = [*@clazz.find(:items).between(5, 10)]
      result.should include(@bike)
      result.size.should == 1
    end

    it "find(:items).between(5, 10).asc(:items)" do
      result = [*@clazz.find(:items).between(1, 10000).asc(:items)]
      result.should == [@bike, @old_bike, @car]
      result.size.should == 3
    end

    it "find(:items).between(5, 10).desc(:items)" do
      result = [*@clazz.find(:items).between(1, 10000).desc(:items)]
      result.should == [@car, @old_bike, @bike]
      result.size.should == 3
    end

    it "find(:items).between(5, 100000).and(:name).between('a', 'd')" do
      result = [*@clazz.find(:items).between(5, 100000).and(:name).between('a', 'd')]
      result.size.should == 2
      result.should include(@bike, @car)
    end

  end

  context "string queries" do

    before(:all) do
      @clazz = create_node_mixin do
        index :city
      end
    end

    it "#index should add an index" do
      n = @clazz.new(:city => 'malmoe')
      new_tx
      @clazz.find('city: malmoe').first.should == n
    end

    it "#index should keep the index in sync with the property value" do
      n = @clazz.new
      n[:city] = 'malmoe'
      new_tx
      n[:city] = 'stockholm'
      new_tx
      @clazz.find('city: malmoe').first.should_not == n
      @clazz.find('city: stockholm').first.should == n
    end

    it "can index and search on two properties if index has the same type" do
      c = Car.new(:wheels => 4, :colour => 'blue')
      new_tx
      Car.find('wheels:"4" AND colour: "blue"').first.should be_kind_of(Vehicle)
      Car.find('wheels:"4" AND colour: "blue"').first.should be_kind_of(Car)
      Car.find('wheels:"4" AND colour: "blue"').should include(c)
    end

    it "can not found if searching on two indexes of different type" do
      c = Car.new(:brand => 'Saab Automobile AB', :wheels => 4, :colour => 'blue')
      new_tx
      Car.find('brand: "Saab"', :type => :fulltext).should include(c)
      Car.find('brand:"Saab" AND wheels: "4"', :type => :exact).should_not include(c)
    end

    it "does allow superclass searching on a subclass" do
      c = Car.new(:wheels => 4, :colour => 'blue')
      new_tx
      Car.find('wheels: 4').first.should == c
      Vehicle.find('wheels: 4').first.should == c
    end

    it "doesn't use the same index for a subclass" do
      bike  = Vehicle.new(:brand => 'monark', :wheels => 2)
      volvo = Car.new(:brand => 'volvo', :wheels => 4)

      # then
      new_tx
      Car.find('brand: volvo', :type => :fulltext).first.should == volvo
      Car.find('wheels: 4', :type => :exact).first.should == volvo
      Vehicle.find('wheels: 2').first.should == bike
      Car.find('wheels: 2').first.should be_nil
    end

    it "returns an empty Enumerable if not found" do
      Car.find('wheels: 999').first.should be_nil
      Car.find('wheels: 999').should be_empty
    end

    it "will remove the index when the node is deleted" do
      c = Car.new(:brand => 'Saab Automobile AB', :wheels => 4, :colour => 'blue')
      new_tx
      Vehicle.find('wheels:"4"').should include(c)

      # when
      c.del
      new_tx

      # then
      Car.find('wheels:"4"').should_not include(c)
      Vehicle.find('colour:"blue"').should_not include(c)
      Vehicle.find('wheels:"4" AND colour: "blue"').should_not include(c)
    end


    it "should work when inserting a lot of data in a single transaction" do
      # Much much fast doing inserting in one transaction
      100.times do |x|
        Neo4j::Node.new
        Car.new(:brand => 'volvo', :wheels => x)
      end
      new_tx


      100.times do |x|
        Car.find("wheels: #{x}").first.should_not be_nil
      end
    end
  end

  context "sorting on date" do
    it "should sort on date" do
      clazz = create_node_mixin do
        property :date_property, :type => Date
        index :date_property
      end
      first_date = clazz.new(:date_property => Date.new(1902,1,1))
      second_date = clazz.new(:date_property => Date.new(2002,1,1))
      third_date = clazz.new(:date_property => Date.new(2012,1,1))
      new_tx
      result = [*clazz.find("date_property: *").desc(:date_property)]
      result.should == [third_date,second_date,first_date]
    end

    it "should sort on date_time" do
      clazz = create_node_mixin do
        property :date_property, :type => DateTime
        index :date_property
      end
      first_date = clazz.new(:date_property => DateTime.new(1902,1,1,10,30))
      second_date = clazz.new(:date_property => DateTime.new(2002,1,1,11,30))
      third_date = clazz.new(:date_property => DateTime.new(2012,1,1,12,30))
      new_tx
      result = [*clazz.find("date_property: *").desc(:date_property)]
      result.should == [third_date,second_date,first_date]
    end

    it "should sort on time" do
      clazz = create_node_mixin do
        property :date_property, :type => Time
        index :date_property
      end
      first_date = clazz.new(:date_property => Time.utc(1902,1,1,1,2,0))
      second_date = clazz.new(:date_property => Time.utc(2002,1,1,1,2,0))
      third_date = clazz.new(:date_property => Time.utc(2012,1,1,1,2,0))
      new_tx
      result = [*clazz.find("date_property: *").desc(:date_property)]
      result.should == [third_date,second_date,first_date]
    end
  end
end
