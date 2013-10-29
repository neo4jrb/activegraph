require 'spec_helper'


describe Neo4j::Rails::Column, :type => :unit do

  without_database
  
  
  describe "#new" do
    it "should create a column object based on a hash" do 
    
      email = Neo4j::Rails::Column.new(:name => "Email", :type => "String",  :index => :exact )
      email.name.should eq("Email")
      email.type.should eq("String")
      email.index.should eq("exact")
    
    end
    
    it "should create a column object even if the index and type are not defined, with type defaulting to string and index as nil." do 
        email = Neo4j::Rails::Column.new(:name => "Email")
        email.name.should eq("Email")
        email.type.should eq("String")
        email.index.should be_nil 
    end
    
    it "should raise an error if no name is passed" do
      lambda { Neo4j::Rails::Column.new(:foo => "bar" )}.should raise_error ArgumentError
    end
    
  end
        
end