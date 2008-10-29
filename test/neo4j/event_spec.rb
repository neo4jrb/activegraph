require 'neo4j'
require 'neo4j/spec_helper'


include Neo4j


#Product.update_index_when(PropertyChangedEvent).fired_on(Customer).with_property('age')).for_each_relation(:orders) do |index, customer, relation, order|
#  order.relations(:products).each do |r|
#    index << {:id => "#{product.neo_node_id}.#{relation.neo_relation_id}.#{r.neo_relation_id}", :"orders.customer.age" => order.total_cost}
#  end
#end

class Person
  include Neo4j::NodeMixin
  properties :age
end


describe "Event" do

  it "should match event of correct type and property value" do
    e = Neo4j::PropertyChangedEvent.new("some_node", "age", "29", "30")
    Neo4j::PropertyChangedEvent.trigger?(e, :property, :age).should be_true
  end

  it "should match event of correct inherited type" do
    Neo4j::Event.trigger?(Neo4j::PropertyChangedEvent.new("some_node", "age", "29", "30")).should be_true
    Neo4j::PropertyChangedEvent.trigger?(Neo4j::Event.new(nil),:property, :age).should be_false
  end
  
  
    it "should not match event of correct type and incorrect property value" do
      e = Neo4j::PropertyChangedEvent.new("some_node", "age", "29", "30")
      Neo4j::PropertyChangedEvent.trigger?(e, :property, :name).should be_false
    end
  
   it "should not match event of correct type and correct property value and incorrect property name" do
      e = Neo4j::PropertyChangedEvent.new("some_node", "age", "29", "30")
      Neo4j::PropertyChangedEvent.trigger?(e, :relation, :name).should be_false
    end
  
    it "should match event of incorrect correct type and incorrect property value" do
      e = Neo4j::PropertyChangedEvent.new("some_node", "age", "29", "30")
      Neo4j::RelationshipAddedEvent.trigger?(e).should be_false
    end

end