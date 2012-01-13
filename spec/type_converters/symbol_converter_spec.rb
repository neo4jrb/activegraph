require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters::SymbolConverter do
  subject { Neo4j::TypeConverters::SymbolConverter }


  its(:convert?, Symbol)  { should be_true }
  its(:convert?, :symbol) { should be_true }
  its(:convert?, Object)  { should be_false }

  its(:to_java, nil)  { should be_nil }
  its(:to_java, :aa)  { should == 'aa' }
  its(:to_java, 'aa') { should == 'aa' }
  its(:to_java, 123)  { should == '123' }


  its(:to_ruby, nil)   { should be_nil }
  its(:to_ruby, 'aa')   { should == :aa  }

  it "should raise of can't symbolize" do
    expect { subject.to_ruby Class }.to raise_error NoMethodError
  end

end
