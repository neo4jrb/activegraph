require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters::DefaultConverter do
  subject { Neo4j::TypeConverters::DefaultConverter }

  its(:to_java, nil)   { should be_nil }
  its(:to_java, "aaa") { should === "aaa" }
  its(:to_java, 123)   { should === 123 }
  its(:to_java, :abc)  { should === :abc } # Hmm
  its(:to_java, -123)  { should === -123 }

  its(:to_ruby, nil)   { should be_nil }
  its(:to_ruby, "aaa") { should === "aaa" }
  its(:to_ruby, -123)  { should === -123 }
  its(:to_ruby, 999999999999999)  { should === 999999999999999 }

end
