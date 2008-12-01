$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")
require 'lucene'
require 'lucene/spec_helper'

describe "Index.find and sort" do
  before(:all) do
    setup_lucene
    @index = Index.new('myindex')
    @index.clear
    @index << {:id => '1', :name => 'zzz', :category=>'abc', :group=>'z'}
    @index << {:id => '2', :name => 'andreas', :category=>'abc',:group=>'z'}
    @index << {:id => '3', :name => 'ted', :category=>'xyz',:group=>'z'}
    @index << {:id => '4', :name => 'zoo', :category=>'abc',:group=>'z'}
    @index << {:id => '5', :name => 'ted', :category=>'abc',:group=>'z'}
    @index << {:id => '6', :name => 'ted', :category=>'zyx',:group=>'z'}
    @index.commit
  end

  it "should handle find and sort by name using Asc" do
    r = @index.find(:group => 'z', :sort_by=>Asc[:name])
    r.size.should == 6
    r[0][:id].should == '2'
    r[4][:id].should == '4'
    r[5][:id].should == '1'
  end

  it "should handle find and sort by name using Asc" do
    r = @index.find(:group => 'z', :sort_by=>Desc[:name])
    r.size.should == 6
    r[0][:id].should == '1'
    r[1][:id].should == '4'
    r[5][:id].should == '2'
  end

  it "should handle find and sort by name" do
    r = @index.find(:group => 'z', :sort_by=>:name)
    r.size.should == 6
    r[0][:id].should == '2'
    r[4][:id].should == '4'
    r[5][:id].should == '1'

    sort_category = r[1][:id] == '5' &&
      r[2][:id] == '3' &&
      r[3][:id] == '6'
    sort_category.should == false
  end

  it "should handle find and sort by name and category using Asc" do
    r = @index.find(:group => 'z', :sort_by=>Asc[:name, :category])
    r.size.should == 6
    r[0][:id].should == '2'
    r[4][:id].should == '4'
    r[5][:id].should == '1'
    r[1][:id].should == '5'
    r[2][:id].should == '3'
    r[3][:id].should == '6'
  end

  it "should handle find and sort by name and category using two Asc" do
    r = @index.find(:group => 'z', :sort_by=>[Asc[:name], Asc[:category]])
    r.size.should == 6
    r[0][:id].should == '2'
    r[4][:id].should == '4'
    r[5][:id].should == '1'
    r[1][:id].should == '5'
    r[2][:id].should == '3'
    r[3][:id].should == '6'
  end

    it "should handle find and sort by ASC name and DESC category" do
    r = @index.find(:group => 'z', :sort_by=>[Asc[:name], Desc[:category]])
    r.size.should == 6
    r[0][:id].should == '2'
    r[4][:id].should == '4'
    r[5][:id].should == '1'
    r[1][:id].should == '6'
    r[2][:id].should == '3'
    r[3][:id].should == '5'
  end

  it "should handle find and sort by name and category" do
    r = @index.find(:group => 'z', :sort_by=>[:name,:category])
    r.size.should == 6
    r[0][:id].should == '2'
    r[4][:id].should == '4'
    r[5][:id].should == '1'
    r[1][:id].should == '5'
    r[2][:id].should == '3'
    r[3][:id].should == '6'
  end

  it "should handle find with string and sort by name" do
    r = @index.find("group:z", :sort_by=>:name)
    r.size.should == 6
    r[0][:id].should == '2'
    r[4][:id].should == '4'
    r[5][:id].should == '1'
  end

end
