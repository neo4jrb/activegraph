require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Model, "lint", :type => :transactional do
  it_should_behave_like AnActiveModel
end


