# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'neo'


describe Neo::Node do
  before(:all) do
    Neo::start
  end

  after(:all) do
    Neo::stop
  end  

  it "should construct a new node"  do
    node = nil
    Neo::transaction {
      node = Neo::Node.new
    }
    node.should be_an_instance_of Neo::Node
  end

  it "should run in a transaction if a block is given at new"  do
    node = Neo::Node.new { }
    node.should be_an_instance_of Neo::Node    
  end
  
  
  it "should do stuff" do
    class Person < Neo::Node
      properties :name, :age 
      #  relations :friend, :child
    end
    
    class Employee < Person
      properties :salary 
      
      def to_s
        "Employee #{@name}"
      end
    end
    
    n1 = Employee.new do |node| # this code body is run in a transaction
      node.name = "kalle"
      node.salary = 10
#      node.bar = "foobar"
    end 
  end
end
#stop

#describe Node do
#  before(:each) do
##    @neo = Neo.new
#  end
#
#  it "should run new in a transaction when a block is provided" do
#    Node.new {|node|
#      node.name = "kalle"
#    }
#  end
#  
#  
#  it "should have setter and getter" do
#    # TODO
#  end
#end

#stop

#############################################################
## Example of usage
#include Neo
#
#start
#
#class Person < Node
#  properties :name, :age 
#  #  relations :friend, :child
#end
#
#class Employee < Person
#  properties :salary 
#  
#  def to_s
#    "Employee #{@name}"
#  end
#end
#
#n1 = Employee.new do |node| # this code body is run in a transaction
#  node.name = "kalle"
#  node.salary = 10
#  node.bar = "foobar"
#end 
#
#n2 = Employee.new do |node| # this code body is run in a transaction
#  node.name = "sune"
#  node.salary = 20
#  node.friends << n1
#end 
#
#puts "Name #{n1.name}, salary: #{n1.salary}"
#
#n2.friends.each {|n| puts "Node #{n.inspect}"}
#
#puts "N1 #{n1.bar}"
#
#
##n1.friends << "hoho"
#
##r1 = RelationshipType.instance 'kalle'
##r2 = RelationshipType.instance 'kalle'
##puts "NAME #{r1.inspect} = #{r2.inspect}"
#
##exit
#
##stop
#
