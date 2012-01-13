require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters::FixnumConverter do
  subject { Neo4j::TypeConverters::FixnumConverter }


  its(:convert?, :fixnum)   { should be_true }
  its(:convert?, Fixnum)    { should be_true }
  its(:convert?, :numeric)  { should be_true }

  its(:convert?, Object)    { should be_false }

  its(:to_java, nil)   { should be_nil }
  its(:to_java, 123)   { should == 123 }
  its(:to_java, 123)   { should == 123 }
  its(:to_java, -123)  { should == -123 }
  # TODO: Where does Bignum fits?
  its(:to_java, 999999999999999)  { should == 999999999999999 }

  its(:to_ruby, nil)   { should be_nil }
  its(:to_ruby, 123)   { should == 123 }
  its(:to_ruby, -123)  { should == -123 }
  its(:to_ruby, 999999999999999)  { should == 999999999999999 }

end
