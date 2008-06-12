# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'lucene'
require 'fileutils'
include Lucene

$INDEX_LOCATION = 'var/index'
#$LUCENE_LOGGER.level = Logger::DEBUG

def delete_all_indexes
  FileUtils.rm_r $INDEX_LOCATION if File.directory? $INDEX_LOCATION
end

describe Transaction do
  
  before(:each) do
    delete_all_indexes
  end
  
  before(:each) do
    # make sure we do not get side effects, if one test forgets to commit a transaction
    Transaction.current.commit if Transaction.running?
  end
  
  it "should have a to_s method" do
    t = Transaction.new 
    t.to_s.should match(/Transaction \[commited=false, rollback=false, indexes=0, object_id=/)
  end
  
  it "should update all indexes when it commits" do
    # given
    index = nil
    Transaction.run do
      index = Index.new('var/index/foo')        
      doc = Document.new(42)
      doc << Field.new('name', 'andreas')
      index.update(doc)
    end  # when it commits&
    
    # then
    result = index.find('name' => 'andreas')
    result.should include(42)
    result.size.should == 1
  end
  
  it "should not index docuements when transaction has rolled back" do
    # given
    index = nil
    Transaction.run do |t|
      index = Index.new('var/index/foo')        
      doc = Document.new(42)
      doc << Field.new('name', 'andreas')
      index.update(doc)
      t.failure
    end  # when it commits&
    
    # then
    result = index.find('name' => 'andreas')
    result.size.should == 0
    
  end
  
  
  it "should not find updated documents from a different thread/transaction" do
    # given
    t1 = Thread.start do 
      Transaction.run do |t|
        index = Index.new('var/index/foo')        
        doc = Document.new(42)
        doc << Field.new('name', 'andreas')
        index.update(doc)
        sleep(0.1)            
      end  # when it commits&
    end
    
    # then
    index = Index.new('var/index/foo')              
    result = index.find('name' => 'andreas')
    result.size.should == 0
    t1.join
    
    # t1 has not commited so we should find it
    result = index.find('name' => 'andreas')
    result.should include(42)
    result.size.should == 1
  end
  
  it "should update an index from several threads" do
    threads = []
    for i in 1..10 do
      for k in 1..5 do      
        threads << Thread.start(i,k) do |ii,kk|
          Transaction.run do |t|
            index = Index.new('var/index/foo')        
            doc = Document.new(ii*10 + kk)
            value = "thread#{ii}#{kk}"
            doc << Field.new('name', value)
            index.update(doc)
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
        result = index.find('name' => value)
        result.should include(i*10 +k)
        result.size.should == 1
      end
    end
  end
  
end

