# 
# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'fileutils'  

require 'lucene'

include Lucene

$INDEX_LOCATION = 'var/index'

def delete_all_indexes
  FileUtils.rm_r $INDEX_LOCATION if File.directory? $INDEX_LOCATION
end

describe Index do
  before(:each) do
    delete_all_indexes
    @index = Index.new($INDEX_LOCATION)
  end

  it "should have a to_s method" do
    @index.to_s.should == "Index [path: 'var/index', 0 documents]"
  end

  it "should contain documents to be updated" do
    doc = Document.new(42)
    doc << Field.new('name', 'andreas')
    @index.update(doc)
    
    # then
    @index.should be_updated(42)
  end
  
  it "should create index files when documents has been commited" do
    doc = Document.new(42)
    doc << Field.new('name', 'andreas')
    @index.update(doc)
    File.directory?($INDEX_LOCATION).should be_false
    
    # when
    @index.commit
    
    # then
    File.directory?($INDEX_LOCATION).should be_true
  end
  
  it "should find indexed fields" do
    # given
    doc = Document.new(42)
    doc << Field.new('name', 'andreas')
    @index.update(doc)
    @index.commit
    
    # when
    result = @index.find('name' => 'andreas')
    
    # then 
    result.should include(42)
    result.size.should == 1
  end
  
  it "should find nothing if the index does not exist" do
    # when
    result = @index.find('name' => 'andreas')
    
    # then 
    result.size.should == 0
  end

  it "should find nothing if the field does not exist" do
    # given
    doc = Document.new(42)
    doc << Field.new('name', 'andreas')
    @index.update(doc)
    @index.commit
    
    # when
    result = @index.find('name' => 'anders')
    
    # then 
    result.size.should == 0
  end

  
  it "should find indexed fields using having the same key" do
    # given
    doc = Document.new(42)
    doc << Field.new('name', 'andreas1')
    doc << Field.new('name', 'andreas2')    
    @index.update(doc)
    @index.commit
    
    # when
    result1 = @index.find('name' => 'andreas1')
    result2 = @index.find('name' => 'andreas2')
    
    # then 
    result1.should include(42)
    result1.size.should == 1
    result2.should include(42)
    result2.size.should == 1
    
  end

  it "should not find the old field if the field has been changed" do
    # given
    doc = Document.new(42)
    doc << Field.new('name', 'andreas')
    @index.update(doc)
    @index.commit
    
    doc = Document.new(42)    
    doc << Field.new('name', 'foo')
    @index.update(doc)
    @index.commit
    
    # when
    andreas_result = @index.find('name' => 'andreas')
    foo_result = @index.find('name' => 'foo')
    
    # then 
    andreas_result.size.should == 0
    foo_result.size.should == 1
    foo_result.should include(42)
  end
  
  it "not find documents that has been removed before commited" do
    # given
    doc = Document.new(42)
    doc << Field.new('name', 'andreas')
    @index.update(doc)
    @index.delete(42)
    @index.commit
    
    # when
    result = @index.find('name' => 'andreas')
    
    # then
    result.size.should == 0
  end
end

describe Document do
  it "contains fields" do
    #given
    doc = Document.new(42)
    doc << Field.new('name', 'andreas')
    doc << Field.new('age', 42)
      
    # then
    doc.size.should == 2
  end
    
  it "should wrap a org.apache.lucene.document.Document java object " do
    doc = Document.new(42)
    doc.to_java.class.should == org.apache.lucene.document.Document
  end
    
end

