require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class RelationshipWithProperty
	include Neo4j::RelationshipMixin
end

class NodeWithRelationship < Neo4j::Rails::Model
	has_one(:other_node).relationship(RelationshipWithProperty)
end

describe RelationshipWithProperty do
  pending do
		subject { @start_node.other_node_rel }
		
		before(:each) do
			@start_node = NodeWithRelationship.new
			@end_node = Neo4j::Rails::Model.new
			@start_node.other_node = @end_node
		end
		
		it { should be_a(Neo4j::Rails::Value::Relationship) }
		
		context "with something" do
			before(:each) do
				subject[:something] = "test setting the property before the relationship is persisted"
			end
			
			it "should still know about something" do
				subject[:something] == "test setting the property before the relationship is persisted"
			end
			
			context "after save" do
				before(:each) do
					@start_node.save
					@end_node.save
					@original_subject = @start_node.other_node_rel
				end
				
				it { should be_a(RelationshipWithProperty) }
				
				it "should still know about something" do
					subject[:something] == "test setting the property before the relationship is persisted"
				end
			end
		end
  end
end

