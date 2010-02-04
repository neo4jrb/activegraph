$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'

describe "Readme Examples" do

  # Called after each example.
  before(:all) do
#    start
  end

  before(:each) do
    start
    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
    stop
  end

  describe "Three Minute Tutorial" do
    it "should run: Example of setting properties" do
      node = Neo4j::Node.new
      node[:name] = 'foo'
      node[:age] = 123
      node[:hungry] = false
    end

    it "should run: Example of getting properties" do
      n = Neo4j::Node.new :name=>'foo', :age=>123, :hungry => false, 4 => 3.14
      n[:name].should == 'foo'
      n[:hungry].should == false
      n[4].should == 3.14
      
      node = Neo4j::Node.new
      node[:name] = 'foo'
      node[:name].should == 'foo'
    end

    it "should run: Example of creating a relationship" do
      node1 = Neo4j::Node.new
      node2 = Neo4j::Node.new
      node1.rels.outgoing(:friends) << node2
    end

    it "should run: Example of getting relationships" do
      node1 = Neo4j::Node.new
      node2 = Neo4j::Node.new
      node1.rels.outgoing(:friends) << node2

      node1.rels.nodes.include?(node2).should be_true # => true - it implements enumerable and other methods
      node1.rels.empty?.should be_false # => false
      node1.rels.first.should_not be_nil # => the first relationship this node1 has which is between node1 and node2
      node1.rels.outgoing.nodes.first.should == node2 # => node2
      node1.rels.outgoing(:friends).first.neo_id.should == node1.rels.first.neo_id # => the first relationship of type :friends
    end


    it "Properties on Relationships" do
      node1 = Neo4j::Node.new
      node2 = Neo4j::Node.new
      node1.rels.outgoing(:friends) << node2

      rel = node1.rels.outgoing(:friends).first
      rel[:since] = 1982
      node1.rels.first[:since] # => 1982 (there is only one relationship defined on node1 in this example)

    end

  end

  describe "Ten Minute Tutorial" do
    before(:all) do
      Neo4j::Transaction.new
      class Person
        include Neo4j::NodeMixin

        # define Neo4j properties
        property :name, :salary, :age, :country

        # define an one way relationship to any other node
        has_n :friends

        # adds a lucene index on the following properties
        index :name, :age, :salary, :country

        def to_s
          name
        end
      end
    end

    before(:each) do
      start
      Neo4j::Transaction.new
      @person = Person.new
    end

    after(:each) do
      Neo4j::Transaction.finish
      stop
    end

    it "Creating a Model" do
      @person.should be_kind_of(Person)
    end

    it "Setting properties" do
      @person.name = 'kalle'
      @person.salary = 10000
    end

    it "Properties and the [] operator" do
      @person['an_undefined_property'] = 'hello'
      @person['an_undefined_property'].should == 'hello'
    end

    it "Relationships" do
      other_node = Neo4j::Node.new
      @person.rels.outgoing(:best_friends) << other_node
      @person.rels.outgoing(:best_friends).first.end_node.should == other_node # => other_node (if there is only one relationship of type 'best_friend' on person)
      @person.rel(:best_friends).end_node.should == other_node
    end

    it "Lucene Queries" do
      p = Person.new
      p.name = 'sune'
      p.salary = 25000
      Neo4j::Transaction.finish
      Neo4j::Transaction.new

      Person.find(:name => 'sune', :salary => 20000..30000).should include(p)
      Person.find("name:sune AND salary:[20000 TO 30000]").should include(p)
    end

    it "Sorting, example" do

      p1 = Person.new
      p1.name = 'sune'
      p1.salary = 25000
      p1.age = 30
      p1.country = 'sweden'

      p2 = Person.new
      p2.name = 'jimmy'
      p2.salary = 20000
      p2.age = 30
      p2.country = 'scotland'

      p3 = Person.new
      p3.name = 'pekka'
      p3.salary = 30000
      p3.age = 30
      p3.country = 'finland'

      p4 = Person.new
      p4.name = 'juha'
      p4.salary = 20000
      p4.age = 30
      p4.country = 'finland'

      Neo4j::Transaction.finish
      Neo4j::Transaction.new

      Person.find(:age => 30).sort_by(:salary).collect{|n| n.to_s}.should == %w[jimmy juha sune pekka]
      Person.find(:age => 30).sort_by(Lucene::Desc[:salary]).collect{|n| n.to_s}.should == %w[pekka sune jimmy juha]
      Person.find(:age => 30).sort_by(Lucene::Desc[:salary], Lucene::Asc[:country]).collect{|n| n.to_s}.should == %w[pekka sune juha jimmy]
      Person.find(:age => 30).sort_by(Lucene::Desc[:salary, :country]).collect{|n| n.to_s}.should == %w[pekka sune jimmy juha]
    end

    it "Search Results" do
      10.times do |c|
        p1 = Person.new
        p1.name = 'kalle'
        p1.salary = 25000
        p1.age = c
        p1.country = 'sweden'
      end

      Neo4j::Transaction.finish
      Neo4j::Transaction.new

      res = Person.find(:name => 'kalle')
      res.size.should == 10
      res.each {|x| x.name.should == 'kalle'}
      res[0].name = 'sune'
      Person.find(:name => 'sune').size.should == 0

      Neo4j::Transaction.finish
      Neo4j::Transaction.new
      Person.find(:name => 'sune').size.should == 1
    end

    it "Creating a Relationships" do
      #Adding a relationship between two nodes:
      person2 = Person.new
      @person.friends << person2

      # The person.friends returns an object that has a number of useful methods (it also includes the Enumerable mixin).
      # Example
      @person.friends.empty?.should be_false # => false
      @person.friends.first.should == person2 # => person2
      @person.friends.include?(person2).should be_true # => true

    end

    it "Deleting a Relationship" do
      #To delete the relationship between person and person2:
      person2 = Person.new
      person3 = Person.new
      @person.friends << person2 << person3

      @person.friends.should include(person2)

      person3.del
      @person.friends_rels.first.del

      @person.friends.should_not include(person2)

      #      If a node is deleted then all its relationship will also be deleted
      #      Deleting a node is performed by using the delete method:
      @person.del
    end

    it "Node Traversals" do
      # Traversing using a filter
      person1 = Person.new; person1.salary = 10000; person1.name = "a"
      person2 = Person.new; person2.salary = 20000; person2.name = "b"
      person3 = Person.new; person3.salary = 10000; person3.name = "c"
      person4 = Person.new; person4.salary = 10000; person4.name = "d"

      @person.friends << person1 << person2 << person3
      person2.friends << person4

      @person.friends{ salary == 10000 }.should include(person1, person3)
      @person.friends{ salary == 10000 }.should_not include(person2, person4)

      # Traversing with a specific depth (depth 1 is default)

      @person.friends{ salary == 10000 }.depth(2).should include(person1, person3, person4)

    end

    it "Example on Relationships" do
      class Movie

      end

      class Role
        include Neo4j::RelationshipMixin
        # notice that neo4j relationships can also have properties
        property :name
      end

      class Actor
        include Neo4j::NodeMixin

        # The following line defines the acted_in relationship
        # using the following classes:
        # Actor[Node] --(Role[Relationship])--> Movie[Node]
        #
        has_n(:acted_in).to(Movie).relationship(Role)
      end

      class Movie
        include Neo4j::NodeMixin
        property :title
        property :year

        # defines a method for traversing incoming acted_in relationships from Actor
        has_n(:actors).from(Actor, :acted_in)
      end

      keanu_reeves = Actor.new
      matrix = Movie.new
      keanu_reeves.acted_in << matrix

      keanu_reeves.acted_in.should include(matrix)

#  or you can also specify this relationship on the incoming node
#  (since we provided that information in the has_n methods).

      keanu_reeves2 = Actor.new
      matrix2 = Movie.new
      matrix2.actors << keanu_reeves2
      keanu_reeves2.acted_in.should include(matrix2)
    end
  end

  describe "The Neo4j Module" do
    it "Start and Stop of the Neo4j" do
      Neo4j.stop
      Neo4j.start
      Neo4j.stop
    end

    it "Neo4j Configuration" do
      Neo4j::Config[:storage_path] = '/home/neo/neodb'
      Neo4j.start
      Neo4j.stop
    end

    it "Accessing the Java Neo4j API" do
      Neo4j.instance.java_class.should == org.neo4j.kernel.EmbeddedGraphDatabase.java_class
      Neo4j::Node.new.should be_kind_of(org.neo4j.graphdb.Node)

      a = Neo4j::Node.new
      b = Neo4j::Node.new
      r = a.add_rel(:friends, b)
      r.should be_kind_of(org.neo4j.graphdb.Relationship)
    end

    it "Node and Relationship Identity" do
      id = Neo4j::Node.new.neo_id
      Neo4j.load_node(id).should be_kind_of(org.neo4j.graphdb.Node)

      # And for relationships:

      rel = Neo4j::Node.new.add_rel(:a_rel_type, Neo4j::Node.new)
      id = rel.neo_id
      # Load the node
      Neo4j.load_rel(id).should be_kind_of(org.neo4j.graphdb.Relationship)
    end

    it "Node Properties" do
      class MyNode
        include Neo4j::NodeMixin
        property :foo, :bar
      end

      node = MyNode.new { |n|
        n.foo = 123
        n.bar = 3.14
      }
      node.foo.should == 123
      # String, Fixnum, Float and true/false
      node.foo = "String"
      node.foo.should == "String"

      node.foo = 3.14
      node.foo.should == 3.14

      node.foo = true
      node.foo.should be_true
    end

    it "Property Types and Marshalling" do
      class MyNode
        include Neo4j::NodeMixin
        property :foo, :type => Object
      end


      node = MyNode.new
      node.foo = [1, "3", 3.14]

      Neo4j.load_node(node.neo_id).foo.should be_kind_of(Array)
    end

    it "Property of type Date and DateTime" do
      Neo4j::Transaction.finish # in this example we will handle the transactions our self

      class MyNode
        include Neo4j::NodeMixin
        property :born, :type => Date
        index :born, :type => Date
      end


      Neo4j::Transaction.run do
        node = MyNode.new
        node.born = Date.new 2008, 05, 06
      end

      Neo4j::Transaction.run do
        born = MyNode.find("born:[20080427 TO 20100203]")[0].born
        born.should be_kind_of(Date)
        born.year.should == 2008
      end

#      Example of using DateTime queries:

      class MyNode
        include Neo4j::NodeMixin
        property :since, :type => DateTime
        index :since, :type => DateTime
      end

      Neo4j::Transaction.run do
        node = MyNode.new
        node.since = DateTime.civil 2008, 04, 27, 15, 25, 59
      end

      Neo4j::Transaction.run do
        since = MyNode.find("since:[200804271504 TO 201002031534]")[0].since
        since.should be_kind_of(DateTime)
        since.hour.should == 15
      end
    end

    it "Finding all nodes" do
      # should at least find the reference node
      nodes = []
      Neo4j.all_nodes{|node| nodes << node}
      nodes.should include(Neo4j.ref_node)
    end


    it "has_n" do
      class Person
        include Neo4j::NodeMixin
        has_n :knows # will generate a knows method for outgoing relationships
      end

#    The generated knows method will allow you to add new relationships, example:

      me = Person.new
      neo = Person.new
      me.knows << neo # me knows neo but neo does not know me

      #   You can add any object to the 'knows' relationship as long as it
      #   includes the Neo4j::NodeMixin, example:

      person = Person.new
      another_node = Neo4j::Node.new
      person.knows << another_node

      person.knows.should include(another_node)
    end

    it "has_n to an outgoing class" do
      #  If you want to express that the relationship should point to a specific class
      # use the 'to' method on the has_n method.

      class Person2
        include Neo4j::NodeMixin
        has_n(:knows).to(Person)
      end

      person = Person2.new
      another_node = Neo4j::Node.new
      person.knows << another_node

      person.knows.should include(another_node)
    end

    it "has_n from an incoming class" do
      #It is also possible to generate methods for incoming relationships by using the
      #'from' method on the has_n method.

      #Example:
      class Person3
        include Neo4j::NodeMixin
        has_n :knows # will generate a knows method for outgoing relationships
        has_n(:known_by).from(Person3, :knows) #  will generate a known_by method for incoming knows relationship
      end


      person = Person3.new
      other_person = Person3.new
      person.knows << other_person

      other_person.known_by.should include(person)

      me = Person3.new
      neo = Person3.new
      neo.known_by << me # me knows neo but neo does not know me

      me.knows.should include(neo)
      neo.knows.should_not include(me)
    end

    it "has_n from an incoming class with 'namespace'" do
      class Order;
      end

      class Product
        include Neo4j::NodeMixin
        has_n(:orders).to(Order)
      end

      class Order
        include Neo4j::NodeMixin
        has_n(:products).from(Product, :orders)
      end

      p = Product.new
      o = Order.new
      o.products << p
      o.products.should include(p)
      p.orders.should include(o)

      p = Product.new
      o = Order.new
      p.orders << o
      p.orders.should include(o)
      o.products.should include(p)
    end


    it "Relationship has_one" do
      class Address;
      end
      class Person4
        include Neo4j::NodeMixin
        has_one(:address).to(Address)
      end

      class Address
        include Neo4j::NodeMixin
        property :city, :road
        has_n(:people).from(Person4, :address)
      end

      p = Person4.new
      p.address = Address.new
      p.address.city = 'malmoe'

      p.address.people.should include(p)

      a = Address.new {|n| n.city = 'malmoe'}
      a.people << Person4.new
      a.people.first.address.should == a
    end


    it "Relationship has_list" do
      class Company
        include Neo4j::NodeMixin
        has_list :employees
      end

      company = Company.new
      employee1 = Neo4j::Node.new
      employee2 = Neo4j::Node.new
      company.employees << employee1 << employee2

      company.employees.should include(employee1, employee2)
    end

    it "Relationship has_list with counter" do
      class Company2
        include Neo4j::NodeMixin
        has_list :employees, :counter => true
      end

      company = Company2.new
      employee1 = Neo4j::Node.new
      employee2 = Neo4j::Node.new
      company.employees << employee1 << employee2
      company.employees.size.should == 2
    end

    it "Deleted List Items" do
      class Company3
        include Neo4j::NodeMixin
        has_list :employees, :counter => true
      end

      company = Company3.new
      employee1 = Neo4j::Node.new
      employee2 = Neo4j::Node.new
      employee3 = Neo4j::Node.new
      company.employees << employee1 << employee2 << employee3
      company.employees.size.should == 3

      employee2.del

      company.employees.should include(employee1, employee3)
      company.employees.size.should == 2
    end

    it "Memberships in lists" do
      class Company4
        include Neo4j::NodeMixin
        has_list :employees, :counter => true
      end
      class Person5
        include Neo4j::NodeMixin
      end
      company = Company4.new
      employee1 = Neo4j::Node.new
      employee2 = Neo4j::Node.new
      employee3 = Neo4j::Node.new

      company.employees << employee1 << employee2 << employee3

      employee1.list(:employees).prev.should == employee2
      employee2.list(:employees).next.should == employee1
      employee1.list(:employees).size.should == 3
    end

    it "Cascade delete, outgoing" do
      class Person6
        include Neo4j::NodeMixin
        has_list :phone_nbr, :cascade_delete => :outgoing
      end

      p = Person6.new
      phone1 = Neo4j::Node.new
      phone1[:number] = '+46123456789'
      phone2 = Neo4j::Node.new
      phone1_id = phone1.neo_id
      phone2_id = phone2.neo_id
      p.phone_nbr << phone1
      p.phone_nbr << phone2

      p.del

      Neo4j.load_node(phone1_id).should_not be_nil
      Neo4j.load_node(phone2_id).should_not be_nil

      # then phone1 and phone2 node will also be deleted.
      Neo4j::Transaction.finish
      Neo4j::Transaction.new

      Neo4j.load_node(phone1_id).should be_nil
      Neo4j.load_node(phone2_id).should be_nil
    end

    it "Cascade delete, incoming" do
      class Phone
        include Neo4j::NodeMixin
        has_list :people, :cascade_delete => :incoming # a list of people having this phone number
      end

      phone1 = Phone.new

      p1 = Neo4j::Node.new
      p2 = Neo4j::Node.new
      phone1.people << p1
      phone1.people << p2

      p1.del
      p2.del

      Neo4j.load_node(phone1.neo_id).should_not be_nil

      # then phone1 will be deleted
      Neo4j::Transaction.finish
      Neo4j::Transaction.new

      Neo4j.load_node(phone1.neo_id).should be_nil
    end

    it "Finding all nodes" do
      require 'neo4j/extensions/reindexer'
      Neo4j.load_reindexer # just if some other RSpecs as unloaded it ...

      class Car
        include Neo4j::NodeMixin
        property :wheels
      end

      class Volvo < Car
      end

      v = Volvo.new
      c = Car.new

      Car.all # will return all relationships from the reference node to car objects
      Volvo.all # will return the same as Car.all

#    To return nodes (just like the relationships method)

      Car.all.nodes.should include(c, v) # => [c,v]
      Volvo.all.nodes.should include(v) # => [v]
      Volvo.all.nodes.should_not include(c)

      Neo4j.unload_reindexer # so that this RSpec does not cause side effects on other RSpecs
    end

    it "Traversing Relationships" do
      class Person7
        include Neo4j::NodeMixin
        has_n :friends
      end

      f = Person7.new
      f1 = Person7.new
      f2 = Person7.new
      f.friends << f1 << f2
      f11 = Person7.new
      f1.friends << f11
      f111 = Person7.new
      f11.friends << f111

      f.friends.should include(f1, f2)
      f.friends.should_not include(f11, f111)
      f.friends.depth(2).should include(f1, f2, f11)
      f.friends.depth(2).should_not include(f111)
      f.friends.depth(:all).should include(f1, f2, f11, f111)
    end

    it "Traversing Relationships: Filtering Nodes" do
      class Person8
        include Neo4j::NodeMixin
        has_n :friends
        property :name
      end

      n1 = Person8.new
      n2 = Person8.new {|n| n.name = 'andreas'}
      n3 = Person8.new
      n1.friends << n2 << n3
      n1.friends{ name == 'andreas' }.should include(n2)
      n1.friends{ name == 'andreas' }.should_not include(n3)
    end

    it "Traversing Nodes of Arbitrary Depth" do
      class Person9
        include Neo4j::NodeMixin
        has_n :friends
      end

      f = Person9.new
      me = Person9.new
      f2 = Person9.new
      f.friends << me << f2
      f11 = Person9.new
      me.friends << f11
      f111 = Person9.new
      f11.friends << f111

      me.incoming(:friends).depth(4).should include(f)
      me.incoming(:friends).depth(4).should_not include(f11, f111)
    end

    it "Traversing Nodes With Several Relationship Types" do
      pending

      class Location
        include Neo4j::NodeMixin
        has_n :contains
        has_n :trips
        property :name
        index :name

        # A Trip can be specific for one global area, such as "see all of sweden" or
        # local such as a 'city tour of malmoe'
        class Trip
          include Neo4j::NodeMixin
          property :name
        end

        # create all nodes
        sweden = Location.new

        # setup the relationship between all nodes

        europe.contains << sweden << denmark
        sweden.contains << malmoe << stockholm

        sweden.trips << sweden_trip
        malmoe.trips << malmoe_trip
        malmoe.trips << city_tour
        stockholm.trips << city_tour # the same city tour is available both in malmoe and stockholm

#    Then we can traverse both the contains and the trips relationship types.
#    Example:
        sweden.outgoing(:contains, :trips).to_a # => [@malmoe, @stockholm, @sweden_trip]

#    It is also possible to traverse both incoming and outgoing relationships, example:

        sweden.outgoing(:contains, :trips).incoming(:contains).to_a # => [@malmoe, @stockholm, @sweden_trip, @europe]

      end
    end

  end

end
