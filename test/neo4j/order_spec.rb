require 'neo4j'
require 'neo4j/spec_helper'

class Order
  include Neo4j::Node
end
class Customer
  include Neo4j::Node
end

class Product
  include Neo4j::Node
  properties :product_name
  properties :units_in_stock
  properties :unit_price
  #  belongs_to :zero_or_more, Order
end

class OrderLine
  include Neo4j::Relation
  properties :units
  properties :unit_price
end

class Order
  properties :total_cost
  properties :dispatched
  has_n(:products).to(Product).relation(OrderLine)
  has_one(:customer).to(Customer)
  
  index "customer.age"
end
    
class Customer
  properties :name      
  properties :age
  
  has_n(:orders).from(Order, :customer) # :zero_or_more, :orders, Order, :customer  # contains incoming relationship of type 'orders'
  has_n(:friends).to(Customer)
  
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
  #   7. What is the mark-up on a certain P&roduct


  before(:each) do
    start
  end

 
  after(:each) do
    stop
  end  

  describe "create relation" do
    it "should allow to create a new dynamic relationship to an order from a customer instance" do
      c = Customer.new
      o = Order.new
      r = c.orders.new(o)
      r.should be_kind_of(Neo4j::DynamicRelation)
    end
    
    it "should allow to create a OrderLine relationship between an order and a product" do
      o = Order.new
      p = Product.new
      order_line = o.products.new(p)
      order_line.should be_kind_of(OrderLine)
    end

  end

  describe "#find" do
    it "should find one customers who has made two orders with a certain total cost" do
      customer = Customer.new
      order1 = Order.new
      order1.total_cost = 100
      order1.customer = customer
      
      order2 = Order.new
      order2.total_cost = 42
      order2.customer = customer
      
      r = Customer.find('orders.total_cost' => '100', 'orders.total_cost' => '42')
      r.size.should == 1
      r.should include(customer)
    end
  
    it "should find two customers who has made two orders with a certain total cost" do
      customer1 = Customer.new
      order1 = Order.new
      order1.total_cost = 100
      order1.customer = customer1
      
      customer2 = Customer.new
      order2 = Order.new
      order2.total_cost = 42
      order2.customer = customer2
  
      r = Customer.find('orders.total_cost' => 100)
      r.size.should == 1
      r.should include(customer1)
      
      r = Customer.find('orders.total_cost' => 42)
      r.size.should == 1
      r.should include(customer2)
    end
    
    it "should not find a customer with 1 order of a total cost of 200 if that order has been deleted" do
      customer = Customer.new
      order = Order.new
      order.total_cost = '200'
      order.customer = customer
        
      Customer.find('orders.total_cost' => '200').size.should == 1
        
      # when
      order.delete
        
      # then
      Customer.find('orders.total_cost' => '200').size.should == 0
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
    
      
    it "should find customer who has a friends of age 30, setting relationship first and then age" do
      c1 = Customer.new
      c2 = Customer.new
      c3 = Customer.new
        
      c1.friends << c2
      c2.friends << c3
      c3.friends << c1
        
      c1.age = 29
      c2.age = 30
      c3.age = 31
        
      res = Customer.find('friends.age' => 30)
      res.size.should == 2
      res.should include(c1, c3)
    end
    
    it "should find customer who has a friend with age 30, setting age first and then relationship" do
      c1 = Customer.new  {|n| n.name = 'c1'; n.age = 29}
      c2 = Customer.new  {|n| n.name = 'c2'; n.age = 30}
      c3 = Customer.new  {|n| n.name = 'c3'; n.age = 31}
      
      c1.friends << c2
      c2.friends << c3
      c3.friends << c1
      
      res = Customer.find(:'friends.age' => 30)
      res.size.should == 2
      res.should include(c1, c3)
    end
    
    it "should find all customer of age 30"  do
      c1 = Customer.new  {|n| n.name = 'c1'; n.age = 29}
      c2 = Customer.new  {|n| n.name = 'c2'; n.age = 30}
      c3 = Customer.new  {|n| n.name = 'c3'; n.age = 30}

      c = Customer.find(:age => 30)
      c.size.should == 2
      c.should include(c2, c3)
    end
    
  
  
    it "should not find a customer by name if the name has changed"  do
      c1 = Customer.new  {|n| n.name = 'c1'; n.age = 29}

      c = Customer.find(:name => 'c1')
      c.size.should == 1
      c.should include(c1)
      
      # when
      c1.name = 'c2'
      
      # then
      c = Customer.find(:name => 'c1')
      c.size.should == 0
    end

    it "should find a customer by the new name if the name has changed"  do
      c1 = Customer.new  {|n| n.name = 'c1'; n.age = 29}

      c = Customer.find(:name => 'c1')
      c.size.should == 1
      c.should include(c1)
      
      # when
      c1.name = 'c2'
      
      # then
      c = Customer.find(:name => 'c2')
      c.size.should == 1
      c.should include(c1)
    end
  
  
  
    it "should not find any customer if they all have been deleted"  do
      c1 = Customer.new  {|n| n.name = 'c1'; n.age = 29}
      c = Customer.find(:age => 29)
      c.size.should == 1
      c1.delete
      c = Customer.find(:age => 29)
      c.size.should == 0
    end

  end
end

