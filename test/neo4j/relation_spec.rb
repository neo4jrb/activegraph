require 'neo4j'
require 'neo4j/spec_helper'




describe "When NOT running in one transaction" do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  
  
  

# TODO reuse specs in node_spec.rb somehow, make it DRY  
  it "It should create a new transaction when updating a relationship" do
    pending "Refactoring needed, should be easier to declare methods as transactional"
    class FooNode 
      include Neo4j::Node
      
      relations :friends
    end
      
    f1 = FooNode.new
    f2 = FooNode.new
    f1.friends << f2
  end
end

# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe Neo4j::Node.to_s, " contains: " do
  before(:all) do
    start
    @transaction = Neo4j::Transaction.new 
    @transaction.start
  end

  after(:all) do
    @transaction.failure # do not want to store anything
    @transaction.finish
    stop
  end  
  
  describe "A customer contains zero or more order" do
    before(:all) do
      class Order
        include Neo4j::Node
        properties :date
      end
      
      class Customer
        include Neo4j::Node
        properties :age, :name
        contains :zero_or_more, Order # default name will be orders
      end

    end
    
    it "should contain the order when customer.orders << order" do
      # given
      customer = Customer.new
      order = Order.new
      
      # when
      customer.orders << order
      
      # then
      customer.orders.to_a.should include(order)
    end
    
    it "should allow to set a property on the customer-order relationship" do
      # given
      customer = Customer.new
      order = Order.new
      relation = customer.orders.new(order) # another way of adding a relationship

      # when      
      relation.my_prop = 'a property'

      # then      
      relation.my_prop.should == 'a property'
    end
    
    it "should not contain the order when the customer-order relation has been deleted" do
      # given
      customer = Customer.new
      order = Order.new
      relation = customer.orders.new(order) # another way of adding a relationship
      
      # when
      relation.delete
      
      # then
      customer.orders.to_a.should_not include(order)
    end
    
    it "should find the order using a filter: customer.orders{ order_id == '2'}" do
      # given
      customer = Customer.new
      order1 = Order.new{|n| n.order_id = '1'}
      order2 = Order.new{|n| n.order_id = '2'}
      order3 = Order.new{|n| n.order_id = '3'}
      customer.orders << order1 << order2 << order3
      
      # when
      result = customer.orders{ order_id == '2'}.to_a
      
      # then
      result.should include(order2)
      result.size.should == 1
    end
  end
end