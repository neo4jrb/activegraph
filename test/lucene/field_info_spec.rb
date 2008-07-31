# 
# To change this template, choose Tools | Templates
# and open the template in the editor.

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
  
#  it "clone" do
#    f1 = FieldInfo.new(:store => true, :foo => 1, :bar=>2)
#    f1.freeze
#    f2 = f1.dup
#    f2[:store] = false
#    f1[:store].should be_true
#    f2[:store].should be_false
#  end
end

