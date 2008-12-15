$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'lucene'

include Lucene

describe FieldInfo do
  it "should have default values" do
    f = FieldInfo.new({})
    f.store?.should == false
    f[:store].should == false
    f[:type].should == String
  end
  
  it "should be possible to override default values" do
    f = FieldInfo.new(:store => true)
    f.store?.should == true
  end

  it "should be possible to set any field" do
    f = FieldInfo.new(:store => true, :foo => 1, :bar=>2)
    f[:foo].should == 1
    f[:bar].should == 2
  end
  
  it "should handle dup - create a new copy of it" do
    f1 = FieldInfo.new(:store => true, :foo => 1, :bar=>2)
    f1.freeze
    f2 = f1.dup
    f2[:store] = false
    f1[:store].should be_true
    f2[:store].should be_false
  end
  
  it "should handle conversion of arrays" do
    f = FieldInfo.new
    c = f.convert_to_lucene(['a','b','c'])
    c.should == ['a', 'b', 'c']
  end
  
  it "should handle conversion of arrays and each value should be converted to correct type" do
    f = FieldInfo.new
    f[:type] = Fixnum
    c = f.convert_to_lucene(['1','2','3'])
    c.should == ["00000000001", "00000000002", "00000000003"]
  end

  it "should convert to correct ruby type from a lucene string value" do
    f = FieldInfo.new
    f[:type] = Fixnum
    f.convert_to_ruby("123").should == 123
  end

  it "should convert Dates to lucene" do
    f = FieldInfo.new
    f[:type] = Date
    f.convert_to_lucene(Date.new(2008,12,15)).should == "20081215"
  end

  it "should convert Dates from lucene" do
    f = FieldInfo.new
    f[:type] = Date
    d = f.convert_to_ruby('20081215')
    d.should be_instance_of(Date)
    d.year.should == 2008
    d.month.should == 12
    d.day.should == 15
  end

end

