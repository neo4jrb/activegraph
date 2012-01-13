require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters::FloatConverter do
  subject { Neo4j::TypeConverters::FloatConverter }

  its(:convert?, Float)   { should be_true }
  its(:convert?, :float)  { should be_true }
  its(:convert?, Object)  { should be_false }

  #TODO: Use precision!


  its(:to_java, nil)    { should be_nil }
  its(:to_java, 123.12) { should === 123.12 }
  its(:to_java, '12.3') { should === 12.3 }

  its(:to_ruby, nil)     { should be_nil }
  its(:to_ruby, 12.34)   { should === 12.34 }
  its(:to_ruby, '12.34') { should === 12.34 }
end
