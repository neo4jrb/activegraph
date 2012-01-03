require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Regressions

  # https://github.com/andreasronge/neo4j/issues/111
  module Issue111
    # Pre-declare classes as everything is cross-referenced
    class Document< Neo4j::Model
    end

    class Property < Neo4j::Model
    end

    class Development < Neo4j::Model
    end



    class Document < Neo4j::Model
      property :file_name, :type => String

      has_one(:development).from(Development, :documents)
      has_n(:properties).from(Property, :documents)
    end


    class Development < Neo4j::Model
      property :name, :type => String

      has_n(:documents).to(Document)
      has_n(:properties).to(Property)
    end


    class Property < Neo4j::Model
      property :name, :type => String

      has_one(:development).from(Development, :properties)
      has_n(:documents).to(Document)
    end



    describe "cross referenced everything" do
      it "should create nested with existing root and other nested" do
        dev = Development.create(:name => 'X')
        doc1 = Document.create(:file_name => 'd1', :development => dev)
        doc2 = Document.create(:file_name => 'd2', :development => dev)

        p = Property.new(:name => 'p1', :documents => [doc1.id, doc2.id])
        p.development = dev
        p.save.should be_true
      end

      it "should update has_one and has_n relations without affecting each other" do
        dev = Development.create(:name => 'X')
        p = Property.create(:name => 'p1')
        doc = Document.new(:file_name => 'd1')

        doc.development = dev
        doc.properties = [p]

        doc.development.should == dev
        doc.properties.size.should == 1
        doc.properties.should include p
      end
    end

  end
end
