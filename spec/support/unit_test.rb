module UnitTest
  def without_database

    let(:new_node) { MockNode.new }

    let(:new_relationship) {  @new_relationship }
    before(:each) do
      # make sure the database is not started
      Neo4j::Core::Database.any_instance.stub(:start) do
        raise "Should have been mocked"
      end
      @new_relationship = nil
      Neo4j::Transaction.stub(:run).and_yield
      Neo4j::Rails::Transaction.stub(:run).and_yield
      Neo4j::Node.stub(:new) { new_node }
      Neo4j::Relationship.stub(:new) { |rel_type, start_node, end_node| @new_relationship = MockRelationship.new(rel_type, start_node, end_node)}

      #Neo4j::RailsRelationship.stub(:load_entity) do |p|
      #  puts "STUB #{p} @new_relationship=#{@new_relationship}"
      #  @new_relationship && p.neo_id == @new_relationship.neo_id
      #end
      #
      #Neo4j::RailsNode.stub(:load_entity) do |p|
      #  puts "STUB NODE #{p} new_node=#{new_node}"
      #  p.neo_id == new_node.neo_id
      #end

    end
  end
end
