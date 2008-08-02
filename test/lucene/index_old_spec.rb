## 
## To change this template, choose Tools | Templates
## and open the template in the editor.
#
#require 'fileutils'  
#
#require 'lucene'
#
#include Lucene
#
#$INDEX_LOCATION = 'var/index'
#
## extend Hits so it is easier to test it
##module Lucene
##  class Hits
##    def include?(id)
##      find
##    end
##  end
##end
#
#def delete_all_indexes
#  FileUtils.rm_r $INDEX_LOCATION if File.directory? $INDEX_LOCATION
#end
#
#describe Index do
#  before(:each) do
#    delete_all_indexes
#    @index = Index.new($INDEX_LOCATION)
#  end
#
#  it "should have a to_s method" do
#    @index.to_s.should == "Index [path: 'var/index', 0 documents]"
#  end
#
#  it "should contain documents to be updated" do
#    doc = Document.new(42)
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    
#    # then
#    @index.should be_updated(42)
#  end
#  
#  it "should create index files when documents has been commited" do
#    doc = Document.new(42)
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    File.directory?($INDEX_LOCATION).should be_false
#    
#    # when
#    @index.commit
#    
#    # then
#    File.directory?($INDEX_LOCATION).should be_true
#  end
#  
#  it "should find indexed fields" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    @index.commit
#    
#    # when
#    result = @index.find('name' => 'andreas')
#    
#    # then 
#    result.size.should == 1    
#    result.should include('42')
#  end
#  
#  it "should find several documents with the same key/value" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#
#    doc = Document.new("43")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    @index.commit
#
#    
#    # when
#    result = @index.find('name' => 'andreas')
#    
#    # then 
#    result.size.should == 2    
#    result.should include('42', '43')
#  end
#  
#  it "should create new document and update index in one operation" do
#    # given
#    @index.new_doc("1") {|doc| doc << Field.new('foo', '1')}
#    @index.new_doc("2") {|doc| doc << Field.new('foo', '1')}
#    @index.new_doc("3") {|doc| doc << Field.new('foo', '1')}
#    @index.commit
#
#    # when
#    result = @index.find('foo' => '1')
#
#    # then 
#    result.size.should == 3
#    result.should include('1','2','3')
#  end
#  
#  it "should find using a inclusive range query" do
#    # given
#    @index.new_doc("0") {|doc| doc << Field.new('foo', 0)}    
#    @index.new_doc("1") {|doc| doc << Field.new('foo', 1)}
#    @index.new_doc("2") {|doc| doc << Field.new('foo', 2)}
#    @index.new_doc("3") {|doc| doc << Field.new('foo', 3)}
#    @index.new_doc("4") {|doc| doc << Field.new('foo', 4)}    
#    @index.commit
#
#    # when
#    result = @index.find('foo' => 1..3)
#    
#    # then
#    result.size.should == 3    
#    result.should include('1','2','3')
#  end
#
#  it "should find using a inclusive range query with padding 0's" do
#    # given
#    @index.new_doc("2") {|doc| doc << Field.new('foo', 3)}    
#    @index.new_doc("30") {|doc| doc << Field.new('foo', 30)}
#    @index.new_doc("32") {|doc| doc << Field.new('foo', 32)}
#    @index.new_doc("100") {|doc| doc << Field.new('foo', 300)}    
#    @index.commit
#
#    # when
#    result = @index.find('foo' => 30..35)
#    
#    # then
#    result.size.should == 2    
#    result.should include('30','32')
#  end
#
#  it "should find using a inclusive range query with padding 0's and Float" do
#    # given
#    @index.new_doc("3.1") {|doc| doc << Field.new('foo', 3.1)}  
#    @index.new_doc("30") {|doc| doc << Field.new('foo', 30)}
#    @index.new_doc("30.2") {|doc| doc << Field.new('foo', 30.2)}
#    @index.new_doc("30.998") {|doc| doc << Field.new('foo', 30.998)}    
#    @index.new_doc("32") {|doc| doc << Field.new('foo', 32)}
#    @index.new_doc("35.01") {|doc| doc << Field.new('foo', 35.01)}    
#    @index.new_doc("300.99") {|doc| doc << Field.new('foo', 300.99)}    
#    @index.commit
#
#    # when
#    result = @index.find('foo' => 30.2..35)
#    
#    # then
#    result.size.should == 3    
#    result.should include('30.2','30.998', '32')
#  end
#
#  it "should find using a inclusive range query with string boundaries" do
#    # given
#    @index.new_doc("a") {|doc| doc << Field.new('foo', 'a')}  
#    @index.new_doc("aa") {|doc| doc << Field.new('foo', 'aa')}
#    @index.new_doc("b") {|doc| doc << Field.new('foo', 'b')}
#    @index.new_doc("c") {|doc| doc << Field.new('foo', 'c')}    
#    @index.new_doc("caa") {|doc| doc << Field.new('foo', 'caa')}    
#    @index.commit
#
#    # when
#    result = @index.find('foo' => 'aa' .. 'c')
#    
#    # then
#    result.size.should == 3    
#    result.should include('aa', 'b', 'c')
#  end
#  
#  it "should find using an exclusive range query" do
#    # given
#    @index.new_doc("0") {|doc| doc << Field.new('foo', 0)}    
#    @index.new_doc("1") {|doc| doc << Field.new('foo', 1)}
#    @index.new_doc("2") {|doc| doc << Field.new('foo', 2)}
#    @index.new_doc("3") {|doc| doc << Field.new('foo', 3)}
#    @index.new_doc("4") {|doc| doc << Field.new('foo', 4)}    
#    @index.commit
#
#    # when
#    result = @index.find('foo' => 1...3)
#    
#    # then
#    # size=1 since we use lucene exclusive range (Ruby does include the first item)
#    result.size.should == 1    
#    result.should include('2')
#  end
#  
#  
#  it "should find nothing if the index does not exist" do
#    # when
#    result = @index.find('name' => 'andreas')
#    
#    # then 
#    result.size.should == 0
#  end
#
#  it "should find nothing if the field does not exist" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    @index.commit
#    
#    # when
#    result = @index.find('name' => 'anders')
#    
#    # then 
#    result.size.should == 0
#  end
#
#  
#  it "should find indexed fields having the same key but different values" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas1')
#    doc << Field.new('name', 'andreas2')    
#    @index.update(doc)
#    @index.commit
#    
#    # when
#    result1 = @index.find('name' => 'andreas1')
#    result2 = @index.find('name' => 'andreas2')
#    
#    # then 
#    result1.size.should == 1    
#    result1.should include("42")
#    result2.size.should == 1    
#    result2.should include("42")
#  end
#
#  it "should refactoring needed" do
#    pending
#    index = Index.new($INDEX_LOCATION)
#    index.add_field(:id, :store => :yes)
#    puts index.field_infos[:id].to_s
#    
#    # DO WE HAVE TO STORE THE INDEX KEY ??????
#    index << {:id => 42, :name => 'andreas'}
#    pending
#  end
#  
#  
#  it "should not find the old field if the field has been changed" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    @index.commit
#    
#    doc = Document.new("42")    
#    doc << Field.new('name', 'foo')
#    @index.update(doc)
#    @index.commit
#    
#    # when
#    andreas_result = @index.find('name' => 'andreas')
#    foo_result = @index.find('name' => 'foo')
#    
#    # then 
#    andreas_result.size.should == 0
#    foo_result.size.should == 1
#    foo_result.should include("42")
#  end
#
#  it "should flag that a document is deleted before a it is commited" do
#    # given a document exists
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    @index.commit
#    
#    # when delete it
#    @index.delete("42")
#    
#    # then it should know it has been marked as deleted
#    @index.should be_deleted("42")
#  end
#  
#  it "should flag that a document is not any longer deleted after it has been deleted and commit" do
#    # given a document exists
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    @index.commit
#    
#    # when delete it and commit it
#    @index.delete("42")
#    @index.commit
#    
#    # then it should not be marked as deleted any more
#    @index.should_not be_deleted("42")
#  end
#  
#  it "should not find documents that has been deleted before commited" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    @index.update(doc)
#    @index.delete("42")
#    @index.commit
#    
#    # when
#    result = @index.find('name' => 'andreas')
#    
#    # then
#    result.size.should == 0
#  end
#  
#  it "should raise an exception when updating a deleted document" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    lambda {
#      @index.delete("42")
#      @index.update(doc)
#    }.should raise_error
#  end
#
#  it "should allow to delete and update an document in two transactions" do
#    # given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    lambda {
#      @index.delete("42")
#      @index.commit
#      @index.update(doc)
#      @index.commit
#    }.should_not raise_error
#  end
#  
#end
#
#describe Document do
#  it "contains fields" do
#    #given
#    doc = Document.new("42")
#    doc << Field.new('name', 'andreas')
#    doc << Field.new('age', "42")
#      
#    # then
#    doc.size.should == 2
#  end
#    
#  it "should wrap a org.apache.lucene.document.Document java object " do
#    doc = Document.new("42")
#    doc.to_java.class.should == org.apache.lucene.document.Document
#  end
#    
#end
#
