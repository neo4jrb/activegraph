require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class TimestampTest < Neo4j::Rails::Model
	property :created_at
	property :updated_at
end

class InheritedTimestampTest < TimestampTest
end

describe TimestampTest do
	it_should_behave_like "a timestamped model"
end

describe InheritedTimestampTest do
	it_should_behave_like "a timestamped model"
end

