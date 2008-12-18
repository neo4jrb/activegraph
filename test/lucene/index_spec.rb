$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")
require 'lucene'
require 'lucene/spec_helper'


describe Index, '(one uncommited document)' do
  before(:each) do
    setup_lucene
    @index = Index.new('my_index')
    @index.clear
    @index << {:id => '42', :name => 'andreas'}
  end

  it "has a to_s method with which says: index path and number of not commited documents" do
    @index.to_s.should == "Index [path: 'my_index', 1 documents]"
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
end


describe Index, '(no uncommited documents)' do
  before(:each) do
    setup_lucene
    @index = Index.new 'myindex'
    @index.clear    
  end

  it "has a to_s method with which says: index path and no uncommited documents" do
    @index.to_s.should == "Index [path: 'myindex', 0 documents]"
  end
  
  it "has no uncommited documents" do
    @index.uncommited.size.should == 0
  end
end


describe Index, ".find (range)" do
  before(:each) do
    setup_lucene
    @index = Index.new('some_index')
    @index.field_infos[:id][:type] = Fixnum    
    @index.field_infos[:value][:type] = Fixnum
  end

  it "should find docs using an inclusive range query" do
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


describe Index, ".find (with TOKENIZED index)" do
  before(:each) do
    setup_lucene
    @index = Index.new('my index')
    @index.field_infos[:name][:tokenized] = true
    
    @index << {:id => "1", :name => 'hej hopp', :name2=>'hej hopp'}
    @index << {:id => "2", :name => 'hello world', :name2=>'hej hopp'}
    @index << {:id => "3", :name => 'hello there', :name2=>'hej hopp'}
    @index << {:id => "4", :name => ['hello', 'hej', '123']}
    @doc1 = @index.uncommited["1"]
    @doc2 = @index.uncommited["2"]
    @doc3 = @index.uncommited["3"]
    @doc4 = @index.uncommited["4"]
    @index.commit
  end

  it "should find indexed documents using the tokenized field" do
    result = @index.find(:name=>"hello")
    result.size.should == 3
    result.should include(@doc2,@doc3, @doc4)
    
    result = @index.find(:name=>"world")
    result.size.should == 1
    result.should include(@doc2)
  end

  it "should find indexed documents using the tokenized field" do
    result = @index.find("name:he*")
    result.size.should == 4
    result.should include(@doc1,@doc2, @doc3)
  end
  
  it "should not find stopwords like 'there'" do
    result = @index.find(:name=>"there")
    result.size.should == 0
  end

  it "should not find indexed documents using the untokenized field" do
    result = @index.find(:name2=>"hello")
    result.size.should == 0
  end
end

describe Index, "#find (with string queries)" do
  before(:each) do
    setup_lucene
    @index = Index.new('myindex')
    @index.field_infos[:name] = FieldInfo.new(:store => true)
    @index << {:id => "1", :name => 'name1', :value=>1, :group=>'a'}
    @index << {:id => "2", :name => 'name2', :value=>2, :group=>'a'}
    @index << {:id => "3", :name => 'name3', :value=>2, :group=>'b'}
    @index << {:id => "4", :name => ['abc', 'def', '123']}
    @doc1 = @index.uncommited["1"]
    @doc2 = @index.uncommited["2"]
    @doc3 = @index.uncommited["3"]
    @doc4 = @index.uncommited["4"]
    @index.commit
  end
  
  
  it "should find a doc by only using its id, index.find('1')" do
    r = @index.find("1")
    r.size.should == 1
    r.should include(@doc1)
  end
  
  it "should find a doc with a specified field, index.find('name:\"name1\"')" do
    r = @index.find("name:'name2'")
    r.size.should == 1
    r.should include(@doc2)
  end

  it "should find a doc with wildcard queries" do
    r = @index.find("name:name*")
    r.size.should == 3
    r.should include(@doc2)
  end

  it "should find handle OR queries" do
    r = @index.find('group:\"b\" OR name:\"name1\"')
    r.size.should == 2
    r.should include(@doc3,@doc1)
  end
  
end


describe Index, ".find (exact match)" do
  before(:each) do
    setup_lucene
    @index = Index.new('myindex')
    @index.field_infos[:name] = FieldInfo.new(:store => true)
    @index << {:id => "1", :name => 'name1', :value=>1, :group=>'a'}
    @index << {:id => "2", :name => 'name2', :value=>2, :group=>'a'}
    @index << {:id => "3", :name => 'name3', :value=>2, :group=>'b'}
    @index << {:id => "4", :name => ['abc', 'def', '123']}
    @doc1 = @index.uncommited["1"]
    @doc2 = @index.uncommited["2"]
    @doc3 = @index.uncommited["3"]
    @doc4 = @index.uncommited["4"]
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

  it "should find a document that has several values for the same key" do
    result = @index.find(:name => 'def')
    result.size.should == 1
    result.should include(@doc4)
    
    result = @index.find(:name => '123')
    result.size.should == 1
    result.should include(@doc4)

    result = @index.find(:name => 'ojo')
    result.size.should == 0
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
    setup_lucene
    @index = Index.new('myindex')
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
    @index << {:id => 42, :name => ['foo','bar','baaz']}
    @index.uncommited['42'][:name].should == ['foo','bar','baaz']
  end
end

describe Index, ".id_field" do
  before(:each) do
    setup_lucene
  end

  it "has a default" do
    index = Index.new 'myindex'
    index.id_field.should == :id
  end
  
  it "can have a specified one" do
    index = Index.new('myindex')
    index.field_infos.id_field = :my_id
    index.id_field.should == :my_id
  end
  
  it "is used to find uncommited documents" do
    # given
    index = Index.new('myindex')
    index.field_infos.id_field = :my_id
    index << {:my_id => '123', :name=>"foo"}
    
    # when then
    index.uncommited['123'][:name].should == 'foo'
  end

  it "can be used to delete documents"  do
    # given
    index = Index.new('myindex')
    index.field_infos.id_field = :my_id
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
    index = Index.new('myindex')
    index.field_infos.id_field = :my_id
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
    setup_lucene
    @index = Index.new('myindex')
    @index.clear    
  end

  it "has a default value for the id_field - store => true" do
    @index.field_infos[:id][:store].should == true
    $LUCENE_LOGGER.level = Logger::INFO
  end

  it "has a default for unspecified fields" do
    @index.field_infos[:foo].should == IndexInfo::DEFAULTS
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


  it "can be used to convert and store Date field" do
    #given
    @index.field_infos[:since][:store] = true
    @index.field_infos[:since][:type] = Date

    @index << {:id => 1, :since => Date.new(2008,3,26)}
    @index.commit

    # when
    hits = @index.find(:id => "1")

    # then
    hits.size.should == 1
    hits[0][:since].should be_instance_of(Date)
    hits[0][:since].year.should == 2008
    hits[0][:since].month.should == 3
    hits[0][:since].day.should == 26
  end


  it "can be used to convert and store DateTime field" do
    #given
    @index.field_infos[:since][:store] = true
    @index.field_infos[:since][:type] = DateTime
    date = DateTime.new(2008,12,18,11,4,59)
    @index << {:id => 1, :since => date}
    @index.commit

    # when
    hits = @index.find(:id => "1")

    # then
    hits.size.should == 1
    hits[0][:since].should be_instance_of(DateTime)
    hits[0][:since].year.should == 2008
    hits[0][:since].month.should == 12
    hits[0][:since].day.should == 18
    hits[0][:since].hour.should == 11
    hits[0][:since].min.should == 4
    hits[0][:since].sec.should == 59
  end

end

describe Index, " when updating a document" do
  before(:each) do
    setup_lucene
    @index = Index.new('myindex')
  end

  it "should remove the field if set to nil" do
    # given
    @index << {:id => 'a', :name=>'andreas'}
    @index.commit
    @index.find(:name => 'andreas').size.should == 1

    # when
    @index << {:id => 'a', :name=>nil}
    @index.commit

    # then
    @index.find(:name => 'andreas').size.should == 0
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
  
  it "should find documents that have the same properties" do
    # given
    @index << {:id => 'a', :name=>'bar'}
    @index << {:id => 'a.1', :name=>'bar'}
    
    @index.commit
    res = @index.find(:name => 'bar')
    res.size.should == 2
  end


  describe "Indexing with Dates" do
    before(:each) do
      setup_lucene
      @index = Index.new('myindex')
      @index.field_infos[:since][:store] = false
      @index.field_infos[:since][:type] = Date

      @index.field_infos[:born][:store] = false
      @index.field_infos[:born][:type] = DateTime
    end


    it "can find an index using a date" do
      #given
      @index << {:id => 1, :since => Date.new(2008,4,26)}
      @index.commit

      # when
      hits = @index.find(:since => Date.new(2008,4,26))

      # then
      hits.size.should == 1
      hits[0][:id].should == '1'
    end

    it "can find an index using a Date range" do
      #given
      @index << {:id => 1, :since => Date.new(2008,4,26)}
      @index.commit

      # then
      @index.find("since:[20080427 TO 20100203]").size.should == 0
      @index.find("since:[20080422 TO 20080425]").size.should == 0
      @index.find("since:{20080426 TO 20090425}").size.should == 0
      @index.find("since:[20080426 TO 20090203]")[0][:id].should == '1'
      @index.find("since:[20080425 TO 20080426]")[0][:id].should == '1'
      @index.find("since:[20000425 TO 20200426]")[0][:id].should == '1'
    end

    it "can find an index using a DateTime range" do
      #given
      # only UTC times are supported 
      @index << {:id => 1, :born => DateTime.civil(2008,4,26,15,58,02)}
      @index.commit

      # then
      @index.find("born:[20080427 TO 20100203]").size.should == 0
      @index.find("born:[20080422 TO 20080425]").size.should == 0
      @index.find("born:[20080426 TO 20090203]")[0][:id].should == '1'
      @index.find("born:[20080425 TO 20080427]")[0][:id].should == '1'
      @index.find("born:[20000425 TO 20200426]")[0][:id].should == '1'

      @index.find("born:[200804260000 TO 200804262359]")[0][:id].should == '1'
      @index.find("born:[200804261500 TO 200804261600]")[0][:id].should == '1'
      @index.find("born:[200804261557 TO 200804261559]")[0][:id].should == '1'
      @index.find("born:[20080426155759 TO 20080426155804]")[0][:id].should == '1'
      @index.find("born:[200804261559 TO 200804261601]").size.should == 0
      @index.find("born:[200804261557 TO 200804261500]").size.should == 0
    end

  end
end

