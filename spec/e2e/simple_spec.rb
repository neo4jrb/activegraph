require 'spec_helper'


describe 'simple things', type: :e2e do
  it 'can do' do
    pending
    #FooPerson = Class.new do
    #end
    #TempModel.set(FooPerson, 'FooPerson')
    #
    #FooPerson.class_eval do
    #  include Neo4j::ActiveNode
    #  property :name
    #  index :name
    #end

    class FooPerson
      include Neo4j::ActiveNode
      property :name, type: String
      index :name
    end

    class BarPerson < FooPerson

    end
    #class FooPerson
    #  include Neo4j::ActiveNode
    #  property :name
    #  index :name
    #end

    FooPerson.should have_attribute(:name)#.of_type(String)
    BarPerson.should have_attribute(:name)#.of_type(String)
    f = FooPerson.create(name: 'andreas')

    b = BarPerson.create(name: 'andreas')

    b.labels.should == :foo
    BarPerson.find(name: 'andreas').should eq(b)
    #
    #puts
  end
end