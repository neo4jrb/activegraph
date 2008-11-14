$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'lucene'

include Lucene

describe Document do
  before(:all) do
    @infos = IndexInfo.new(:my_id)
    @infos[:value] = {:type => Float}
  end
  
  it "should have field infos" do
    doc = Document.new(@infos)    
    doc.field_infos.should be_equal(@infos)
  end
  
  it "should convert fields" do
    #$LUCENE_LOGGER.level = Logger::DEBUG
    doc = Document.new(@infos, {:my_id => 1, :value => '1.23'})    
    doc[:my_id].should be_kind_of(String)
    doc[:value].should be_kind_of(Float)    
    doc[:my_id].should == "1"
    doc[:value].should == 1.23
    #$LUCENE_LOGGER.level = Logger::WARN
  end
  
  it "should handle multiple fields with the same id" do
    doc = Document.new(@infos, {:my_id => 1, :name => ['abc', 'def', '123']})    
    doc[:name].should == ['abc', 'def', '123']
  end
end

