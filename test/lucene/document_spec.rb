require 'lucene'

include Lucene

describe Document do
  before(:all) do
    @infos = FieldInfos.new(:my_id, {:value => FieldInfo.new(:type => Float)})
  end
  
  it "should have field infos" do
    doc = Document.new(@infos)    
    doc.field_infos.should be_equal(@infos)
  end
  
  it "should convert fields" do
    doc = Document.new(@infos, {:my_id => 1, :value => '1.23'})    
    doc[:my_id].should be_kind_of(String)
    doc[:value].should be_kind_of(Float)    
    doc[:my_id].should == "1"
    doc[:value].should == 1.23
  end
end

