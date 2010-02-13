$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'

describe "Neo4j::BatchInserter" do

  it "should use batch_inserter for Neo4j.migrate! :batch_insert => true " do
    pending
    Neo4j.migration 1, :my_first do
      up do
        a = Neo4j::Node.new :name => 'a'
        b = Neo4j::Node.new :name => 'b'

        Neo4j::Relationship.new(:friend, a, b, :since => '2001-01-01')
      end
      down do

      end
    end

    Neo4j.migrate! :batch_insert => true
  end
end