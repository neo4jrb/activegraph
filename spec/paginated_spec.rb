require 'spec_helper'

describe Neo4j::Paginated do
  let(:source)    { (1..30).to_a }
  let(:page)      { 2 }
  let(:per_page)  { 5 }

  subject { Neo4j::Paginated.create_from source, page, per_page }


  its(:current_page)  { should == 2 }
  its(:size)          { should == 5 }
  its(:to_a)          { should == [6, 7, 8, 9, 10] }
  its(:total)         { should == source.length }

end
