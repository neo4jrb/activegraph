require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Rails::Model, "#paginate" do
  context "pagination of #all" do
    before(:all) do
      @class = create_model do
        property :flavour
      end
    end
    before(:each) do
      7.times{|i| @class.create(:flavour => "flavour_#{i}")}
    end

    it "can return the first page" do
      res = @class.all.paginate(:page => 1, :per_page => 3)
      res.map{|x| x.flavour}.should == %w[flavour_0 flavour_1 flavour_2]
    end

    it "can return the next page" do
      res = @class.all.paginate(:page => 2, :per_page => 3)
      res.map{|x| x.flavour}.should == %w[flavour_3 flavour_4 flavour_5]
    end

    it "can return the last page" do
      res = @class.all.paginate(:page => 3, :per_page => 3)
      res.map{|x| x.flavour}.should == %w[flavour_6]
    end

  end

  context "pagination of #find result" do
    class ModelWithFulltextIndex < Neo4j::Rails::Model
      property :flavour
      property :number
      index :flavour
      index :number
    end

    before(:each) do
      7.times { |i| ModelWithFulltextIndex.create!(:flavour => "vanilla", :number => i.to_s) }
    end

    it "can return the first page" do
      res = ModelWithFulltextIndex.all("flavour: vanilla").desc(:number).paginate(:page => 1, :per_page => 3)
      res.map { |x| x.number }.should == %w[6 5 4]
    end

  end


  context "pagination of #has_n nodes" do
    before(:all) do
      @class = create_model do
        property :name
        has_n :friends
      end
    end
    before(:each) do
      @model = @class.create!(:name => 'base')
      7.times{|i| @model.friends << @class.create(:name => "name_#{i}")}
      @model.save!
    end

    it "can return the first page" do
      res = @model.friends.paginate(:page => 1, :per_page => 3)
      res.map{|x| x.name}.should == %w[name_0 name_1 name_2]
    end

    it "can return the next page" do
      res = @model.friends.paginate(:page => 2, :per_page => 3)
      res.map{|x| x.name}.should == %w[name_3 name_4 name_5]
    end

    it "can return the last page" do
      res = @model.friends.paginate(:page => 3, :per_page => 3)
      res.map{|x| x.name}.should == %w[name_6]
    end

  end


  context "pagination of #has_n relationships" do
    before(:all) do
      @class = create_model do
        property :name
      end
    end
    before(:each) do
      @model = @class.create!(:name => 'base')
      7.times{|i| Neo4j::Rails::Relationship.create!(:knows, @model, @class.create(:name => "name_#{i}"), :number => i)}
    end

    it "can return the first page" do
      res = @model.rels(:knows, :outgoing).paginate(:page => 1, :per_page => 3)
      res.map{|x| x[:number]}.should == [0, 1, 2]
    end


  end

end
