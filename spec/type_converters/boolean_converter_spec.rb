require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters::BooleanConverter do
  subject { Neo4j::TypeConverters::BooleanConverter }


  its(:convert?, :boolean)  { should be_true }
  its(:convert?, :numeric)  { should be_false }
  its(:convert?, Object)    { should be_false }

  its(:to_java, nil)   { should be_nil }
  its(:to_java, 123)   { should be_true }
  its(:to_java, true)  { should be_true }
  its(:to_java, 'aa')  { should be_true }
  its(:to_java, 0)     { should be_true }

  its(:to_java, false) { should be_false }
  its(:to_java, '0')   { should be_false } # Isn't it a bit inconsistent with 'aa'?


  its(:to_ruby, nil)   { should be_nil }
  its(:to_ruby, 123)   { should be_true }
  its(:to_ruby, true)  { should be_true }
  its(:to_ruby, 'aa')  { should be_true }
  its(:to_ruby, 0)     { should be_true }

  its(:to_ruby, false) { should be_false }
  its(:to_ruby, '0')   { should be_false }

end
