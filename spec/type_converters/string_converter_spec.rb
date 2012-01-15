require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters::StringConverter do
  subject { Neo4j::TypeConverters::StringConverter }

  its(:convert?, String)  { should be_true }
  its(:convert?, :string) { should be_true }
  its(:convert?, :text)   { should be_true }
  its(:convert?, Object)  { should be_false }

  its(:to_java, nil)  { should be_nil }
  its(:to_java, 'aa') { should === 'aa' }
  its(:to_java, 123)  { should === '123' }

  its(:to_ruby, nil)  { should be_nil }
  its(:to_ruby, 'aa') { should === 'aa' }
  its(:to_ruby, 123)  { should === '123' }
end
