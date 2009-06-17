$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'




describe "CustomerA,Order,Product" do
  #    * An CustomerA can have One or Many Orders
  #    * An Order can contain One or Many Products (OrderLines)
  #    * A Product can be associated with One or Many Orders
  #    * A Supplier can supply One or Many Products

  #   1. Which Products have been Ordered by a CustomerA
  #   2. What date/time was a particular Order dispatched
  #   3. How many open Orders do we have in the system
  #   4. What is the Total Order Cost for a certain Order
  #   5. Which Supplier supplies a particular Product
  #   6. How many of a certain Product do we have in stock
  #   7. What is the mark-up on a certain P&roduct


  before(:all) do
    undefine_class :Order, :CustomerA, :Product


    class Order
      include Neo4j::NodeMixin
    end
    class CustomerA
      include Neo4j::NodeMixin
    end

    class Product
      include Neo4j::NodeMixin
      property :product_name
      property :units_in_stock
      property :unit_price
      #  belongs_to :zero_or_more, Order
    end

    class OrderLine
      include Neo4j::RelationshipMixin
      property :units
      property :unit_price
    end

    class Order
      property :total_cost
      property :dispatched
      has_n(:products).to(Product).relationship(OrderLine)
      has_one(:customer).to(CustomerA)

      index "customer.age"
    end

    class CustomerA
      property :name
      property :age

      has_n(:orders).from(Order, :customer) # :zero_or_more, :orders, Order, :customer  # contains incoming relationship of type 'orders'
      has_n(:friends).to(CustomerA)

      def init_node(name='hej', age=102)
        self.name = name
        self.age = age
      end

      def to_s
        "CustomerA [name=#{name}]"
      end

      index "age"
      index "name"

      # when Order with a relationship to CustomerA
      # For each customer in an order update total_cost
      index "orders.total_cost"
      index "friends.age"
    end
  end


  before(:each) do
    start
  end


  after(:each) do
    stop
  end

  describe "create relationship" do

    before(:each) do
      Neo4j::Transaction.new
    end

    after(:each) do
      Neo4j::Transaction.finish
    end

    it "should allow to create a new dynamic relationship to an order from a customer instance" do
      c = CustomerA.new
      o = Order.new
      r = c.orders.new(o)
      r.should be_kind_of(Neo4j::Relationships::Relationship)

    end

    it "should allow to set properties on the customer - order relationship" do
      c = CustomerA.new
      o = Order.new
      r = c.orders.new(o)

      r[:foo_bar] = "hej"

      r[:foo_bar].should == "hej"
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
      customer = nil
      Neo4j::Transaction.run do
        customer = CustomerA.new
        order1 = Order.new
        order1.total_cost = 100
        order1.customer = customer

        order2 = Order.new
        order2.total_cost = 42
        order2.customer = customer
      end

      Neo4j::Transaction.run do
        r = CustomerA.find('orders.total_cost' => '100', 'orders.total_cost' => '42')
        r.size.should == 1
        r.should include(customer)
      end
    end

    it "should find two customers who has made two orders with a certain total cost" do
      customer1 = customer2 =  nil
      Neo4j::Transaction.run do
        customer1 = CustomerA.new
        order1 = Order.new
        order1.total_cost = 100
        order1.customer = customer1

        customer2 = CustomerA.new
        order2 = Order.new
        order2.total_cost = 42
        order2.customer = customer2
      end

      Neo4j::Transaction.run do
        r = CustomerA.find('orders.total_cost' => 100)
        r.size.should == 1
        r.should include(customer1)

        r = CustomerA.find('orders.total_cost' => 42)
        r.size.should == 1
        r.should include(customer2)
      end
    end


    it "should not find a customer with 1 order of a total cost of 200 if that order has been deleted" do
      order = nil
      Neo4j::Transaction.run do
        customer = CustomerA.new
        order = Order.new
        order.total_cost = '200'
        order.customer = customer
      end

      Neo4j::Transaction.run do
        CustomerA.find('orders.total_cost' => '200').size.should == 1
      end

      # when
      Neo4j::Transaction.run do
        order.delete
      end

      # then
      Neo4j::Transaction.run do
        CustomerA.find('orders.total_cost' => '200').size.should == 0
      end
    end


    it "should find customer who has a friends of age 30, setting relationship first and then age" do
      c1 = c2 = c3 = nil
      Neo4j::Transaction.run do
        c1 = CustomerA.new
        c2 = CustomerA.new
        c3 = CustomerA.new

        c1.friends << c2
        c2.friends << c3
        c3.friends << c1

        c1.age = 29
        c2.age = 30
        c3.age = 31
      end

      Neo4j::Transaction.run do
        res = CustomerA.find('friends.age' => 30)
        res.size.should == 2
        res.should include(c1, c3)
      end
    end


    it "should find customer who has a friend with age 30, setting age first and then relationship" do
      c1 = c2 = c3 = nil
      
      Neo4j::Transaction.run do
        c1 = CustomerA.new('c1', 29)
        c2 = CustomerA.new('c2', 30)
        c3 = CustomerA.new('c3', 31)

        c1.friends << c2
        c2.friends << c3
        c3.friends << c1
      end

      Neo4j::Transaction.run do
        res = CustomerA.find('friends.age' => 30)
        res.size.should == 2
        res.should include(c1, c3)
      end
    end

    it "should find all customer of age 30"  do
      c1 = c2 = c3 = nil
      Neo4j::Transaction.run do
        c1 = CustomerA.new('c1', 29)
        c2 = CustomerA.new('c2', 30)
        c3 = CustomerA.new('c3', 30)
      end

      Neo4j::Transaction.run do
        c = CustomerA.find(:age => 30)
        c.size.should == 2
        c.should include(c2, c3)
      end
    end



    it "should not find a customer by name if the name has changed"  do
      c1 = Neo4j::Transaction.run do
        CustomerA.new('c1', 29)
      end

      Neo4j::Transaction.run do
        c = CustomerA.find(:name => 'c1')
        c.size.should == 1
        c.should include(c1)
      end


      # when
      Neo4j::Transaction.run do
        c1.name = 'c2'
      end


      # then
      Neo4j::Transaction.run do
        c = CustomerA.find(:name => 'c1')
        c.size.should == 0
      end

    end

    it "should find a customer by the new name if the name has changed"  do
      c1 = Neo4j::Transaction.run do
        CustomerA.new('c1', 29)
      end

      c = Neo4j::Transaction.run do
        c = CustomerA.find(:name => 'c1')
        c.size.should == 1
        c.should include(c1)
        c
      end


      # when
      Neo4j::Transaction.run do
        c1.name = 'c2'
      end

      # then
      Neo4j::Transaction.run do
        c = CustomerA.find(:name => 'c2')
        c.size.should == 1
        c.should include(c1)
      end
    end



    it "should not find any customer if they all have been deleted"  do
      c1 = Neo4j::Transaction.run do
        CustomerA.new('c1', 29)
      end

      Neo4j::Transaction.run do
        c = CustomerA.find(:age => 29)
        c.size.should == 1
      end

      Neo4j::Transaction.run do
        c1.delete
      end

      Neo4j::Transaction.run do
        c = CustomerA.find(:age => 29)
        c.size.should == 0
      end

    end

  end

end
