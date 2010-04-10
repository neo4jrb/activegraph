$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")
require 'lucene'
require 'lucene/spec_helper'


describe Lucene::Transaction do
  
  before(:each) do
    setup_lucene
  end
  
  it "should have a to_s method" do
    t = Lucene::Transaction.new 
    t.to_s.should match(/Transaction \[commited=false, rollback=false, indexes=0, object_id=/)
  end
  
  it "should reuse Index instance in the same transaction" do
    # given
    index = nil
    Lucene::Transaction.run do
      index1 = Index.new('var/index/foo')        
      index2 = Index.new('var/index/foo')        
      index1.object_id.should == index2.object_id
    end  # when it commits&
  end

  it "should create a new instance of Index if running in a new transaction" do
    # given
    index1 = nil
    index2 = nil
    Lucene::Transaction.run do
      index1 = Index.new('var/index/foo')        
    end 
    
    Lucene::Transaction.run do
      index2 = Index.new('var/index/foo')        
    end 

    index1.object_id.should_not == index2.object_id
  end
  
  it "should update all indexes when it commits" do
    # given
    index = nil
    Lucene::Transaction.run do
      index = Index.new('var/index/foo')        
      index << {:id => '1', :name => 'andreas'}
    end  # when it commits&
      
    # then
    result = index.find('name' => 'andreas')
    result.size.should == 1    
    result[0][:id].should == '1'
  end
    
  it "should not index docuements when transaction has rolled back" do
    # given
    index = nil
    Lucene::Transaction.run do |t|
      index = Index.new('var/index/foo')        
      index << {:id => '1', :name => 'andreas'}
      t.failure
    end  # when it commits
      
    # then
    result = index.find('name' => 'andreas')
    result.size.should == 0
  end
    
    
  it "should not find uncommited documents for a different thread" do
    # given
    t1 = Thread.start do 
      Lucene::Transaction.new
      index = Index.new('var/index/foo')
      index << {:id => '1', :name => 'andreas'}
      index = Index.new('var/index/foo')
      index.uncommited['1'].should_not be_nil
    end

    t1.join
    index = Index.new('var/index/foo')
    index.uncommited['1'].should be_nil
  end
    
  it "should update an index from several threads" do
    threads = []
    for i in 1..10 do
      for k in 1..5 do      
        threads << Thread.start(i,k) do |ii,kk|
          Lucene::Transaction.run do |t|
            index = Index.new('var/index/foo')        
            id = (ii*10 + kk).to_s
            value = "thread#{ii}#{kk}"
            index << {:id => id, :name => value}
          end  # when it commits&
        end
      end
    end
      
      
    threads.each {|t| t.join}
  
    # make sure we can find those    
    index = Index.new 'var/index/foo'    
    for i in 1..10 do
      for k in 1..5 do
        value = "thread#{i}#{k}"
        result = index.find(:name => value)
        result.size.should == 1
        result[0][:id].should == (i*10 +k).to_s
      end
    end
  end
  
end

