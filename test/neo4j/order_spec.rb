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
  has :one_or_more, :products, Product
  has :one, :customer, Customer
end
    
class Customer
  include Neo4j::Node
  properties :name      
  properties :age
  
  belongs_to :zero_or_more, :orders, Order, :customer  # contains incoming relationship of type 'orders'
  has :zero_or_more, :friends, Customer
  
  def to_s
    "Customer [name=#{name}]"
  end
  
  index "age"
  index "name"
  
  # when Order with a relationship to Customer
  # For each customer in an order update total_cost
  index "orders.total_cost"
  index "friends.age"
  
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
    
    @c1 = Customer.new  {|n| n.name = 'calle'; n.age = 30}
    #p = Product.new {|n| n.product_name = "bike"; n.units_in_stock=3; n.unit_price = 100.50}
    @order1 = Order.new # {|n| n.total_cost = '200'; n.dispatched = "20080104"; n.customer = @c1 }#n.products << p }
    @order1.customer = @c1
    
    @order2 = Order.new
    @order2.total_cost = '42'
    @order2.customer = @c1
    @c2 = Customer.new{|n| n.name = 'adam'; n.age = 29}
    @c3 = Customer.new{|n| n.name = 'bertil'; n.age = 30}
  end

 
  after(:each) do
    stop
  end  

  it "should find customers who has made two orders with a total cost of 100 and 42" do
    #@c1.relations.incoming(:customer).nodes.each {|n| puts "ORDER IS #{n.inspect}"}
    @order1.total_cost = '100'
    
    r = Customer.find('orders.total_cost' => '100')
    r.size.should == 1
    r.should include(@c1)
    r = Customer.find('orders.total_cost' => '42')
    r.size.should == 1
    r.should include(@c1)
  end
  
  it "should generate methods for navigation of relationship between Customer,Order,Product" do
    o = Order.new
    o.should respond_to(:customer)
    o.should respond_to(:customer=)
    o.should respond_to(:products)
    o.should_not respond_to(:products=)
    
    c = Customer.new
    o.customer = c
    o.customer.should == c
  end

  
  it "should find customer with friends age of 1" do
    c1 = Customer.new  {|n| n.name = 'c1'; n.age = 1}
    c2 = Customer.new  {|n| n.name = 'c2'; n.age = 2}
    c3 = Customer.new  {|n| n.name = 'c3'; n.age = 3}
    
    c1.friends << c2
    c2.friends << c3
    c3.friends << c1
    
    # when, TODO, not needed should reindex when node created !
    c1.age = 1
    c2.age = 2
    c3.age = 3
    
    res = Customer.find(:'friends.age' => 1)
    res.size.should == 2
    res.should include(c1, c3)
  end
  
  it "should find customer with friends age of 1 before changing value" do
    pending
    c1 = Customer.new  {|n| n.name = 'c1'; n.age = 1}
    c2 = Customer.new  {|n| n.name = 'c2'; n.age = 2}
    c3 = Customer.new  {|n| n.name = 'c3'; n.age = 3}
    
    c1.friends << c2
    c2.friends << c3
    c3.friends << c1
    
    res = Customer.find(:'friends.age' => 1)
    res.size.should == 2
    res.should include(c1, c3)
  end
  
  it "should find all customer of age 30"  do
    c = Customer.find(:age => 30)
    c.size.should == 2
    c.should include(@c1, @c3)
  end

  it "should not find any customer of age 30 if there age has changed"  do
    c = Customer.find(:age => 30)
    c.size.should == 2
    
    # when
    c[0].age = 31
    c[1].age = 32
    
    # then
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

