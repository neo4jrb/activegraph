require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Index::Indexer, "#add_index_batch" do
  context "has no index" do
    before(:each) do
      @clazz = create_node_mixin do
      end
    end

    it "should not index any fields" do
      indexer        = @clazz._indexer
      index_provider = mock("index provider")
      indexer.add_index_batch(42, {'name' => 'andreas'}, index_provider)
    end
  end

  context "subclass" do
    before(:each) do
      @base_class = create_node_mixin do
        index :name
      end

      @sub_class  = create_node_mixin_subclass(@base_class) do
        index :city
      end
    end

    it "add index on subclass adds index on base classes" do
      index_provider = mock("index provider")
      base_index          = mock("base index")
      sub_index          = mock("sub index")

      index_provider.should_receive(:node_index).twice do |*args|
        classname = args[0]
        case classname
          when "#{@base_class}-exact" : base_index
          when "#{@sub_class}-exact" : sub_index
          else fail("Unknown class to index #{classname}")
        end
      end


      sub_index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 2
        args[1]['city'].should == 'malmoe'
        args[1]['name'].should == 'andreas'
      end

      base_index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 1
        args[1]['name'].should == 'andreas'
      end

      indexer = @sub_class._indexer
      indexer.add_index_batch(42, {'city' => 'malmoe', 'name' => 'andreas'}, index_provider)
    end
  end


  context "declared 3 exact lucene indexes" do
    before(:each) do
      @clazz = create_node_mixin do
        index :name
        index :age
        index :value
      end
    end

    it "add index on property if property was included" do
      index_provider = mock("index provider")
      index          = mock("node index")
      index_provider.should_receive(:node_index).once.and_return(index)
      index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 2
        args[1]['name'].should == 'andreas'
        args[1]['value'].should == 'my value'
      end
      indexer = @clazz._indexer
      indexer.add_index_batch(42, {'name' => 'andreas','x' => 'y', 'value' => 'my value'}, index_provider)
    end
  end


  context "declared one exact and one fulltext field" do
    before(:each) do
      @clazz = create_node_mixin do
        index :name
        index :desc, :type => :fulltext
      end
    end

    it "add index on property if property was included" do
      index_provider = mock("index provider")
      index          = mock("node index")
      index_provider.should_receive(:node_index).once.and_return(index)
      index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 1
        args[1]['name'].should == 'andreas'
      end
      indexer = @clazz._indexer
      indexer.add_index_batch(42, {'name' => 'andreas'}, index_provider)
    end

    it "add NOT index on property if property was NOT included" do
      index_provider = mock("index provider")
      indexer        = @clazz._indexer
      indexer.add_index_batch(42, {'colour' => 'blue'}, index_provider)
    end

    it "only declared indexes should be indexed" do
      index_provider = mock("index provider")
      index          = mock("node index")
      index_provider.should_receive(:node_index).once.and_return(index)
      index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 1
        args[1]['name'].should == 'kalle'
      end

      indexer = @clazz._indexer
      indexer.add_index_batch(42, {'colour' => 'blue', 'name' => 'kalle'}, index_provider)
    end

    it "knows which index (exact or fulltext) to use for each property" do
      index_provider = mock("index provider")
      exact_index    = mock("exact index")
      fulltext_index = mock("fulltext index")

      index_provider.should_receive(:node_index).twice do |*args|
        case args[1]['type']
          when 'exact' :
            exact_index
          when 'fulltext' :
            fulltext_index
          else
            fail("Unknown index type #{args[1]['type']}")
        end
      end

      exact_index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 1
        args[1]['name'].should == 'kalle'
      end

      fulltext_index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 1
        args[1]['desc'].should == 'bla bla'
      end

      indexer = @clazz._indexer
      indexer.add_index_batch(42, {'colour' => 'blue', 'name' => 'kalle', 'desc' => 'bla bla'}, index_provider)
    end
  end
end
