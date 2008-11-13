$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'lucene'

include Lucene

describe FieldInfos do
  it "should have an id_field" do
    f = FieldInfos.new(:my_id)
    f.id_field.should == :my_id
  end
  
  it "should have a default for any key" do
    f = FieldInfos.new(:my_id)
    f[42].should == FieldInfos::DEFAULTS
    FieldInfos::DEFAULTS[:store].should == false
    f[42][:store].should == false
  end
  
  it "can set a field by a hash of infos " do
    # given
    f = FieldInfos.new(:my_id)
    # when
    f[:value] = {:type => Float}
    # then
    f[:value].should be_kind_of(FieldInfo)
    f[:value][:type].should == Float
  end

  it "can set a field by a FieldInfo" do
    # given
    f = FieldInfos.new(:my_id)
    # when
    f[:value] = FieldInfo.new(:type => Float)
    # then
    f[:value].should be_kind_of(FieldInfo)
    f[:value][:type].should == Float
  end

  it "can set a individual property of a FieldInfo" do
    # given
    f = FieldInfos.new(:my_id)
    
    # when
    f[:value][:type] = Float
    
    # then
    f[:value].should be_kind_of(FieldInfo)
    f[:value][:type].should == Float
  end

  it "can set several individual properties of a FieldInfo" do
    # given
        $LUCENE_LOGGER.level = Logger::DEBUG
    f = FieldInfos.new(:my_id)
    
    # when
    f[:value][:type] = Float
    f[:foo][:type] = Fixnum
    f[:value][:bar] = 42
    
    # then
    f[:value].object_id.should_not == f[:foo].object_id
    
    f[:value][:type].should == Float
    f[:foo][:type].should == Fixnum
    f[:value][:bar].should == 42
        $LUCENE_LOGGER.level = Logger::WARN
  end
  
end

describe "FieldInfos::DEFAULTS" do
  it "should have default values" do
    FieldInfos::DEFAULTS[:store].should == false
    FieldInfos::DEFAULTS[:type].should == String
  end
end
