$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")
require 'lucene'
require 'lucene/spec_helper'

describe "Index.find and sort" do
  before(:all) do
    setup_lucene
    @index = Index.new('myindex')
    @index.clear
    @index << {:id => '1', :name => 'zzz', :group=>'z'}
    @index << {:id => '2', :name => 'andreas', :group=>'z'}
    @index << {:id => '3', :name => 'ted', :group=>'z'}        
    @index << {:id => '4', :name => 'zoo', :group=>'z'}        
    @index.commit
  end
  
  it "should handle find and sort by name" do
    r = @index.find(:group => 'z', :sort_by=>:name)
    r.size.should == 4
    r[0][:id].should == '2'
    r[1][:id].should == '3'    
    r[2][:id].should == '4'    
    r[3][:id].should == '1'            
  end
  
  it "should handle find with string and sort by name" do
    r = @index.find("group:z", :sort_by=>:name)
    r.size.should == 4
    r[0][:id].should == '2'
    r[1][:id].should == '3'    
    r[2][:id].should == '4'    
    r[3][:id].should == '1'            
  end
  
end
