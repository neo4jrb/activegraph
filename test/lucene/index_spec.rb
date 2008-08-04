# 
# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'fileutils'  

require 'lucene'

include Lucene

$INDEX_DIR = 'var/index'


def delete_all_indexes
  FileUtils.rm_r $INDEX_DIR if File.directory? $INDEX_DIR
end

describe Index, '(one uncommited document)' do
  before(:each) do
    delete_all_indexes
    @index = Index.new($INDEX_DIR)    
    @index.clear
    @index << {:id => '42', :name => 'andreas'}
  end

  it "has a to_s method with which says: index path and number of not commited documents" do
    @index.to_s.should == "Index [path: 'var/index', 1 documents]"
  end

  it "should be empty after clear" do
    # when 
    @index.clear
    
    # then
    @index.uncommited.size.should == 0
  end

  it "should be empty after commit" do
    # when 
    @index.commit
    
    # then
    @index.uncommited.size.should == 0
  end
  
  it "contains one uncommited document" do
    # then
    @index.uncommited.size.should == 1
    @index.uncommited['42'][:id].should == '42'
    @index.uncommited['42'][:name].should == 'andreas'
  end
  
  it "should not have created an index file" do
    File.directory?($INDEX_DIR).should be_false
  end
end


describe Index, '(no uncommited documents)' do
  before(:each) do
    delete_all_indexes
    @index = Index.new($INDEX_DIR)    
    @index.clear    
  end

  it "has a to_s method with which says: index path and no uncommited documents" do
    @index.to_s.should == "Index [path: 'var/index', 0 documents]"
  end
  
  it "has no uncommited documents" do
    @index.uncommited.size.should == 0
  end
end


describe Index, ".find (range)" do
  before(:each) do
    delete_all_indexes
    Index.clear($INDEX_DIR)
    @index = Index.new($INDEX_DIR)    
    @index.field_infos[:id][:type] = Fixnum    
    @index.field_infos[:value][:type] = Fixnum
  end

  it "should find docs using a inclusive range query" do
    # given
    @docs = {}
    for i in 1..5 do
      @index << {:id => i, :value=>i}
      @docs[i] = @index.uncommited[i]
    end
    @index.commit

    # when
    result = @index.find(:value => 2..4)
    
    # then
    result.size.should == 3    
    result.should include(@docs[2], @docs[3], @docs[4])
  end
  
  it "should find docs using an inclusive range query with padding 0's" do
    # given
    @index << {:id => 3, :value=>3}
    @index << {:id => 30, :value=>30}
    @index << {:id => 32, :value=>32}
    @index << {:id => 100, :value=>100}
    doc30 = @index.uncommited[30]
    doc32 = @index.uncommited[32]
    @index.commit

    # when
    result = @index.find(:value => 30..35)
    
    # then
    result.size.should == 2    
    result.should include(doc30, doc32)
  end
  
end

describe Index, ".find (exact match)" do
  before(:each) do
    delete_all_indexes
    Index.clear($INDEX_DIR)
    @index = Index.new($INDEX_DIR)    
    @index.field_infos[:name] = FieldInfo.new(:store => true)
    @index << {:id => "1", :name => 'name1', :value=>1, :group=>'a'}
    @index << {:id => "2", :name => 'name2', :value=>2, :group=>'a'}
    @index << {:id => "3", :name => 'name3', :value=>2, :group=>'b'}
    @doc1 = @index.uncommited["1"]
    @doc2 = @index.uncommited["2"]
    @doc3 = @index.uncommited["3"]
    @index.commit
  end
  
  it "should find indexed documents using the id field" do
    result = @index.find(:id=>"1")
    result.size.should == 1
    result.should include(@doc1)
  end

  it "should find indexed documents using any field" do
    result = @index.find(:name=>"name1")
    result.size.should == 1
    result.should include(@doc1)
    
    result = @index.find(:value=>1)
    result.size.should == 1
    result.should include(@doc1)
  end

  it "should find nothing if it does not exist" do
    result = @index.find(:name=>"name")
    result.should be_empty
  end

  
  it "should find several documents having the same property" do
    result = @index.find(:value => 2)
    result.size.should == 2
    result.should include(@doc2,@doc3)
  end
  
  it "should find using several fields" do
    result = @index.find(:value => 2, :group => 'a')
    result.size.should == 1
    result.should include(@doc2)
  end

  
  it "should return document containing the stored fields for that index" do
    # when
    result = @index.find(:id=>"1")
    
    # then
    doc = result[0]
    doc.id.should == '1'
    doc[:name].should == 'name1'
    doc[:value].should be_nil # since its default FieldInfo has :store=>false
  end
  
end

describe Index, "<< (add documents to be commited)" do
  before(:each) do
    delete_all_indexes
    Index.clear($INDEX_DIR)
    @index = Index.new($INDEX_DIR)    
    @index.field_infos[:foo] = FieldInfo.new(:store => true)
  end
  
  it "converts all fields into strings" do
    @index << {:id => 42, :foo => 1}
    @index.uncommited['42'][:foo].should == '1'
  end

  it "can add several documents" do
    @index << {:id => "1", :foo => 'a'} << {:id => "2", :foo => 'b'}
    
    # then
    @index.uncommited.size.should == 2
    @index.uncommited['1'][:foo].should == 'a'
    @index.uncommited['2'][:foo].should == 'b'
  end

  it "can have several values for the same key" do
    pending
    @index << {:id => 42, :name => ['foo','bar','baaz']}
  end
end

describe Index, ".id_field" do
  before(:each) do
    delete_all_indexes
    Index.clear($INDEX_DIR)
  end

  it "has a default" do
    index = Index.new($INDEX_DIR)    
    index.id_field.should == :id
  end
  
  it "can have a specified one" do
    index = Index.new($INDEX_DIR, :my_id)    
    index.id_field.should == :my_id
  end
  
  it "is used to find uncommited documents" do
    # given
    index = Index.new($INDEX_DIR, :my_id)    
    index << {:my_id => '123', :name=>"foo"}
    
    # when then
    index.uncommited['123'][:name].should == 'foo'
  end

  it "can be used to delete documents"  do
    # given
    index = Index.new($INDEX_DIR, :my_id)    
    index.field_infos[:my_id][:type] = Fixnum
    index << {:my_id => 123, :name=>"foo"}
    index.commit
    index.find(:name=>'foo').should_not be_empty
    
    # when delete it
    index.delete(123)
    index.commit
    
    # then
    index.find(:name=>'foo').should be_empty
  end
  
  it "must be included in all documents" do
    # given
    index = Index.new($INDEX_DIR, :my_id)    

    # when not included
    lambda {
      index << {:id=>2, :name=>"foo"} # my_id missing
    }.should raise_error # then it should raise an exception
  end
end

describe Index, ".new" do
  it "should not create a new instance if one already exists (singelton)" do
    index1 = Index.new($INDEX_DIR)  
    index2 = Index.new($INDEX_DIR)  
    index1.object_id.should == index2.object_id
  end
  
  it "should be possible to create a new instance even if one already exists" do
    index1 = Index.new($INDEX_DIR)  
    index1.clear
    index2 = Index.new($INDEX_DIR)  
    index1.object_id.should_not == index2.object_id
  end
end

describe Index, ".field_infos" do
  before(:each) do
    delete_all_indexes
    @index = Index.new($INDEX_DIR)  
    @index.clear    
  end

  it "has a default value for the id_field - store => true" do
    @index.field_infos[:id][:store].should == true
  end

  it "has a default for unspecified fields" do
    @index.field_infos[:foo].should == FieldInfos::DEFAULTS
  end

  it "should use a default for unspecified type, for example all fields has default :type => String" do
    @index.field_infos[:value] = FieldInfo.new(:store => true, :foo => 1)
    
    # should use default field info for unspecified
    @index.field_infos[:value][:type].should == String
  end
  
  it "has a default that can be overridden" do
    # given
    @index.field_infos[:bar][:type] = Float
    # then
    @index.field_infos[:bar][:type].should == Float
    @index.field_infos[:id][:type].should == String
    @index.field_infos[:name][:type].should == String    
  end
  
  it "can be used to convert properties" do
    #given
    @index.field_infos[:bar][:store] = true
    @index.field_infos[:bar][:type] = Float
    @index.field_infos[:id][:type] = Fixnum
    @index.field_infos[:name][:store] = true
    
    @index << {:id => 1, :bar => 3.14, :name => "andreas"}
    @index.commit
    
    # when
    hits = @index.find(:name => 'andreas')
    
    @index.field_infos[:id][:type].should == Fixnum
    # then
    hits.size.should == 1
    hits[0][:id].should == 1
    hits[0][:bar].should == 3.14
    hits[0][:name].should == 'andreas'
  end
end

describe Index, " when updating a document" do
  before(:each) do
    delete_all_indexes
    @index = Index.new($INDEX_DIR)  
    @index.clear    
  end
  
  it "should not find the old field if the field has been changed" do
    # given
    @index << {:id => 'a', :name=>'andreas'}
    @index.commit
    @index.find(:name => 'andreas').should_not be_empty
    
    # when it change
    @index << {:id => 'a', :name=>'foo'}
    @index.commit
    
    # then it can not be found
    @index.find(:name => 'andreas').should be_empty
  end

  it "should not find a deleted document" do
    # given
    @index << {:id => 'a', :name=>'andreas'}
    @index.commit
    @index.find(:name => 'andreas').should_not be_empty
    
    # when it is deleted
    @index.delete('a')
    @index.commit
    
    # then it can not be found
    @index.find(:name => 'andreas').should be_empty
  end

end

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

