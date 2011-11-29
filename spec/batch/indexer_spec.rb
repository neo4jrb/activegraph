require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Batch::Indexer do
  before(:each) do
    Neo4j.threadlocal_ref_node = nil    
  end
  
  def setup_index_provider(index_provider, exact_indexes, fulltext_indexes = {})
    indexes = {}
    exact_indexes.each_pair { |k, v| indexes["#{k}_exact"] = v }
    fulltext_indexes.each_pair { |k, v| indexes["#{k}_fulltext"] = v }

    index_provider.should_receive(:node_index).any_number_of_times do |*args|
      index_name = args[0]
      raise "No index for '#{index_name}', got #{indexes.keys.join(', ')}" unless indexes[index_name]
      indexes[index_name]
    end
  end

  describe "#index_entity" do
    context "has no index" do
      before(:each) do
        @clazz = create_node_mixin do
        end
      end

      it "should not index any fields" do
        indexer                              = Neo4j::Batch::Indexer.instance_for(@clazz)
        Neo4j::Batch::Indexer.index_provider = mock("index provider")
        indexer.index_entity(42, {'name' => 'andreas'})
      end
    end

    context "has a subclass" do
      before(:each) do
        @base_class = create_node_mixin do
          index :name
        end

        @sub_class  = create_node_mixin_subclass(@base_class) do
          index :city
        end
      end

      it "add index on subclass adds index on base classes" do
        index_provider                       = mock("index provider")
        Neo4j::Batch::Indexer.index_provider = index_provider
        base_index                           = mock("base index")
        sub_index                            = mock("sub index")

        setup_index_provider(index_provider, {@base_class => base_index, @sub_class => sub_index}, {})

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

        indexer = Neo4j::Batch::Indexer.instance_for(@sub_class)
        indexer.index_entity(42, {'city' => 'malmoe', 'name' => 'andreas'})
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
        index_provider                       = mock("index provider")
        Neo4j::Batch::Indexer.index_provider = index_provider
        index                                = mock("node index")
        index_provider.should_receive(:node_index).once.and_return(index)
        index.should_receive(:add) do |*args|
          args[0].should == 42
          args[1].size.should == 2
          args[1]['name'].should == 'andreas'
          args[1]['value'].should == 'my value'
        end
        indexer = Neo4j::Batch::Indexer.instance_for(@clazz)
        indexer.index_entity(42, {'name' => 'andreas', 'x' => 'y', 'value' => 'my value'})
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
        index_provider                       = mock("index provider")
        Neo4j::Batch::Indexer.index_provider = index_provider
        index                                = mock("node index")
        index_provider.should_receive(:node_index).once.and_return(index)
        index.should_receive(:add) do |*args|
          args[0].should == 42
          args[1].size.should == 1
          args[1]['name'].should == 'andreas'
        end
        indexer = Neo4j::Batch::Indexer.instance_for(@clazz)
        indexer.index_entity(42, {'name' => 'andreas'})
      end

      it "add NOT index on property if property was NOT included" do
        index_provider                       = mock("index provider")
        Neo4j::Batch::Indexer.index_provider = index_provider
        indexer                              = Neo4j::Batch::Indexer.instance_for(@clazz)
        indexer.index_entity(42, {'colour' => 'blue'})
      end

      it "only declared indexes should be indexed" do
        index_provider                       = mock("index provider")
        Neo4j::Batch::Indexer.index_provider = index_provider
        index                                = mock("node index")
        index_provider.should_receive(:node_index).once.and_return(index)
        index.should_receive(:add) do |*args|
          args[0].should == 42
          args[1].size.should == 1
          args[1]['name'].should == 'kalle'
        end

        indexer = Neo4j::Batch::Indexer.instance_for(@clazz)
        indexer.index_entity(42, {'colour' => 'blue', 'name' => 'kalle'})
      end

      it "knows which index (exact or fulltext) to use for each property" do
        index_provider                       = mock("index provider")
        Neo4j::Batch::Indexer.index_provider = index_provider
        exact_index                          = mock("exact index")
        fulltext_index                       = mock("fulltext index")

        setup_index_provider(index_provider, {@clazz =>exact_index}, {@clazz => fulltext_index})

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

        indexer = Neo4j::Batch::Indexer.instance_for(@clazz)
        indexer.index_entity(42, {'colour' => 'blue', 'name' => 'kalle', 'desc' => 'bla bla'})
      end
    end

  end

  describe "#index_node_via_rel" do

    it "does not index anything unless the index is decalred with an :via=>" do
      clazz                                = create_node_mixin do
        index :name
      end
      index_provider                       = mock("index provider")
      Neo4j::Batch::Indexer.index_provider = index_provider
      indexer = Neo4j::Batch::Indexer.instance_for(clazz)
      indexer.index_node_via_rel('friends', 42, {'colour' => 'blue', 'name' => 'kalle', 'desc' => 'bla bla'})
    end

    it "when a related node is created it should update the other nodes index" do
      index_provider                       = mock("index provider")
      Neo4j::Batch::Indexer.index_provider = index_provider

      fulltext_index                 = mock("fulltext index")
      setup_index_provider(index_provider, {}, {Actor => fulltext_index})

      fulltext_index.should_receive(:add) do |*args|
        args[0].should == 42
        args[1].size.should == 1
        args[1]['title'].should == 'matrix'
      end

      # we create a relationship between
      # Actor[Node] --(Role[Relationship])--> Movie[Node], rel_type = Movie#acted_in
      indexer = Neo4j::Batch::Indexer.instance_for(Movie)
      indexer.index_node_via_rel("Movie#acted_in", 42, {'title' => 'matrix'})
    end

    it "does not index when there is no indexer for the given relationship" do
      index_provider                       = mock("index provider")
      Neo4j::Batch::Indexer.index_provider = index_provider
      # We only index when a movie node has been created
      indexer = Neo4j::Batch::Indexer.instance_for(Actor)
      indexer.index_node_via_rel("Movie#acted_in", 42, {'title' => 'matrix'})
    end

    it "does not index when there is no index for the property" do
      index_provider                       = mock("index provider")
      Neo4j::Batch::Indexer.index_provider = index_provider
      # We only index when a movie node has been created
      indexer = Neo4j::Batch::Indexer.instance_for(Actor)
      indexer.index_node_via_rel("Movie#acted_in", 42, {'name' => 'matrix'})
    end

    it "can index several properties at once" do
      clazz = create_node_mixin do
        has_n(:out_bars).to(self)
        has_n(:in_bars).from(self, :out_bars)
        index :name, :via => :in_bars  # index all bars relationships
      end

      index_provider                       = mock("index provider")
      Neo4j::Batch::Indexer.index_provider = index_provider
      
      index                 = mock("exact index")
      setup_index_provider(index_provider,{clazz => index})

      index.should_receive(:add) do |*args|
        args[0].should == 123
        args[1].size.should == 1
        args[1]['name'].should == 'abc'
      end

      rel_type = clazz._decl_rels[:out_bars].rel_type
      indexer = Neo4j::Batch::Indexer.instance_for(clazz)

      # pretend we created a relationship between two clazz nodes using relationship :out_bars
      indexer.index_node_via_rel(rel_type, 123, {'name' => 'abc', 'x' => 'y'})
    end
  end
end

