require 'neo4j'
require 'neo4j/spec_helper'

class Order; end
class Customer; end

class Product
  include Neo4j::Node
  properties :product_name
  properties :units_in_stock
  properties :unit_price
  #  belongs_to :zero_or_more, Order
end
    
class Order
  include Neo4j::Node
  properties :total_cost
  properties :dispatched
  has :one_or_more, Product
  has :one, Customer
end
    
class Customer
  include Neo4j::Node
  properties :name      
  properties :age
  
  #belongs_to :zero_or_more, Order  # contains incoming relationship of type 'orders'
    
  def to_s
    "Customer [name=#{name}]"
  end
  
  index :age
  
  # when Order with a relationship to Customer
  # For each customer in an order update total_cost
  # index "orders.total_cost"
  
  # For each orders in a product AND for each customer in a order add the name
  # index "orders.products.name"
end



describe "Customer,Order,Product" do
  #    * An Customer can have One or Many Orders
  #    * An Order can contain One or Many Products (OrderLines)
  #    * A Product can be associated with One or Many Orders
  #    * A Supplier can supply One or Many Products

  #   1. Which Products have been Ordered by a Customer
  #   2. What date/time was a particular Order dispatched
  #   3. How many open Orders do we have in the system
  #   4. What is the Total Order Cost for a certain Order
  #   5. Which Supplier supplies a particular Product
  #   6. How many of a certain Product do we have in stock
  #   7. What is the mark-up on a certain Product


  before(:each) do
    start
    
    # setup fixture
    
    @c1 = Customer.new{|n| n.name = 'calle'; n.age = 30}
    p = Product.new {|n| n.product_name = "bike"; n.units_in_stock=3; n.unit_price = 100.50}
    o = Order.new {|n| n.total_cost = '200'; n.dispatched = "20080104"; n.customer = @c1; n.products << p }
    
    @c2 = Customer.new{|n| n.name = 'adam'; n.age = 29}
    
    @c3 = Customer.new{|n| n.name = 'bertil'; n.age = 30}
  end

 
  after(:each) do
    stop
  end  

  it "should have a Order#customer method" do
    o = Order.new
    o.should respond_to(:customer)
    o.should respond_to(:customer=)
    o.should respond_to(:products)
    o.should_not respond_to(:products=)
    
    c = Customer.new
    o.customer = c
    o.customer.should == c
  end

  it "should find all customer of age 30"  do
    c = Customer.find(:age => 30)
    c.size.should == 2
    c.should include(@c1, @c3)
  end

  it "should not find any customer of age 30 if there age has changed"  do
    c = Customer.find(:age => 30)
    c.size.should == 2
    c[0].age = 31
    c[1].age = 32
    c = Customer.find(:age => 30)
    c.size.should == 0
  end

  it "should not find any customer if they have been deleted"  do
    c = Customer.find(:age => 30)
    c.size.should == 2
    c[0].delete
    c[1].delete
    c = Customer.find(:age => 30)
    c.size.should == 0
  end
end

#index :name # does
#
#index :orders, :name
#
#Customer.update_index_when(PropertyChangedEvent).with_property('name') do |index, id, customer|
#  index << {:id => id, :name => customer.name}
#end
#
#Customer.update_index_when(NodeDeletedEvent) do |index, id, customer|
#  index.delete(id)
#end
#
# Some examples how to index relationship to support advanced queries:

# Example 1
# 
# Find customers who have made orders with a total cost above ...
#Customer.find("orders.total_cost > 20000")
#
## Needs index on orders.total_cost:
#Customer.index "orders.total_cost"
#
## Which will generate the following event listener/index updater
#
#Customer.update_index_when(PropertyChangedEvent.fired_on(Order).with_property('total_cost')).for_each_relation(:customer) do |index, order, relation, customer|
#  index << {:id => "#{customer.neo_node_id}.#{relation.neo_relation_id}", :total_cost => order.total_cost}
#end
#
#Customer.update_index_when(RelationshipAddedEvent.fired_on(Order).with_relation_name('customer')) do |index, order, relation, customer|
#  index << {:id => "#{customer.neo_node_id}.#{relation.neo_relation_id}", :total_cost => order.total_cost}
#end
#
#Customer.update_index_when(RelationshipDeletedEvent.fired_on(Order).with_relation_name('customer')) do |index, order, relation, customer|
#  index.delete("#{customer.neo_node_id}.#{relation.neo_relation_id}")
#end
#
#etc...

# Example 2
#
# Find all products that customer with age between 20 & 30 have bought 
#Product.find('orders.customer.age' => 20..30)
#
## That will need index on 
#Product.index('order.customer.age')
#
## Which will generate the following event listener/index updater
#
#Product.update_index_when(PropertyChangedEvent.fired_on(Customer).with_property('age')).for_each_relation(:orders, :products) do |id, index, customer|
#  #order.relations(:products).each do |r|
#   # id = "#{product.neo_node_id}.#{relation.neo_relation_id}.#{r.neo_relation_id}"
#    index << {:id => id, :"orders.customer.age" => customer.age}
#  end
#end
#
#Product.update_index_when(RelationshipDeletedEvent.fired_on(Order).with_relation_name('customer')) do |index, order, relation, customer|
#  order.relations(:products).each do |r|
#    product = r.end_node
#    index.delete("#{product.neo_node_id}.#{relation.neo_relation_id}.#{r.neo_relation_id}")
#  end
#end
#
##etc...


# PropertyChangedEvent Order - ignore all
# RelationshipAddedEvent match   Order.customer  index customer.age
# RelationshipDeletedEvent match Order.customer delete index customer.age
# PropertyChangedEvent match     Customer.age   index customer.age
# NodeDeletedEvent               Customer       delete index.customer.age
