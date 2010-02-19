$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'

describe "Neo4j#migrations" do
  before(:each) { start; Neo4j::Transaction.new }
  after(:each)  {  Neo4j.migrations.clear; Neo4j::Transaction.finish; stop }

  it "should not run any migration if db is on given version" do
    Neo4j.ref_node[:db_version] = 1
    Neo4j.migration 1, :create_articles do
      up do
        raise "Should not have been called"""

      end
      down do
        raise "Should not have been called"
      end
    end

    # when starting
    Neo4j.migrate!
  end

  it "should not run any migration if there are no migrations" do
    Neo4j.migrate!
  end

  it "should set the version on the ref node" do
    Neo4j.stop

    Neo4j.migration 1, :create_articles do
      up do
      end
      down do
      end
    end
    # when starting
    Neo4j.start

    # then
    Neo4j.db_version.should == 1
  end

  it "should call one 'up' block when running one up migration" do
    called = false
    Neo4j.migration 1, :create_articles do
      up do
        called = true
      end
      down do
        raise "Should not have been called"
      end
    end

    # when starting
    Neo4j.migrate!

    # then
    called.should be_true
  end

  it "should call each 'up' block in correct order when running several up migration" do
    called = []
    Neo4j.migration 1, :first do
      up do
        called << 1
      end
      down do
        raise "Should not have been called"
      end
    end

    Neo4j.migration 3, :third do
      up do
        called << 3
      end
      down do
        raise "Should not have been called"
      end
    end

    Neo4j.migration 2, :second do
      up do
        called << 2
      end
      down do
        raise "Should not have been called"
      end
    end

    # when starting
    Neo4j.migrate!

    # then
    called.should == [1, 2, 3]
    Neo4j.db_version.should == 3
  end

  it "should call one 'down' block migration when running one down migration" do
    called = false
    Neo4j.ref_node[:db_version] = 1
    Neo4j.migration 1, :create_articles do
      up do
        raise "Should not have been called"
      end
      down do
        called = true
      end
    end

    # when starting
    Neo4j.migrate! 0

    # then
    called.should be_true
    Neo4j.db_version.should == 0
  end

  it "should evaluate the up and down method in the context of the reference node" do
    #More RDocs for Migrations [#108 state:open]
    called_up = called_down = nil
    Neo4j.migration 1, :create_articles do
      up do
        called_up = self
      end
      down do
        called_down = self
      end
    end

    # when starting
    Neo4j.migrate! 1
    called_up.should be_kind_of(Neo4j::ReferenceNode)
    Neo4j.migrate! 0
    called_down.should be_kind_of(Neo4j::ReferenceNode)
  end

  it "should run any migration when neo4j starts without needing to call Neo4j.migrate!" do
    Neo4j.stop
    called = false
    Neo4j.migration 1, :create_articles do
      up do
        called = true
      end
      down do
        raise
      end
    end

    Neo4j.start
    called.should == true
  end

end

describe Neo4j::MigrationMixin do

  before(:each) { start; Neo4j::Transaction.new }
  after(:each)  {  Neo4j.migrations.clear; Neo4j::Transaction.finish; stop }


  class PersonInfo
    include Neo4j::NodeMixin
    include Neo4j::MigrationMixin
    include Neo4j::LazyMigrationMixin
    property :name
  end

  PersonInfo.migration 1, :split_name do
    # Split name into two properties
    class PersonInfo
      property :surname
      property :given_name
    end


    up do
      self.given_name = self[:name].split[0]
      self.surname = self[:name].split[1]
      self.name = nil
    end

    down do
      self.name = "#{self[:given_name]} #{self[:surname]}"
      self.surename = nil
      self.given_name = nil
    end
  end
  it "should be possible to migrate only when node is loaded" do
    kalle = PersonInfo.new :name => 'kalle stropp'

    # when
    PersonInfo.migrate!

    # then
    k2 = Neo4j.load_node(kalle.neo_id)
    k2.surname.should == 'stropp'
    k2.given_name.should == 'kalle'
  end
end