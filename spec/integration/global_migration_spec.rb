require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Neo4j#migration", :type => :transactional do
  pending 
  after(:each) do
    Neo4j::GlobalMigration.reset_migrations!
    Neo4j.db_version.should == 0
  end

  it "should not run any migration if db is on given version" do
    Neo4j.ref_node[:_db_version] = 1
    Neo4j.migration 1, :create_articles do
      up do
        raise "Should not have been called" ""
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
    Neo4j.db_version.should == 0
  end

  it "should set the version on the ref node" do
    Neo4j.shutdown

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
    called                      = false
    Neo4j.ref_node[:_db_version] = 1
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
    called_up.should == Neo4j::GlobalMigration
    Neo4j.migrate! 0
    called_down.should == Neo4j::GlobalMigration
  end

  it "should run any migration when neo4j starts without needing to call Neo4j.migrate!" do
    Neo4j.shutdown
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
