require 'spec_helper'

describe 'Neo4j::ActiveNode#find' do
  let(:clazz) do
    UniqueClass.create do
      include Neo4j::ActiveNode
      property :name
    end
  end

  it 'can find nodes that exists' do
    foo =clazz.create(name: 'foo')
    expect(clazz.find(conditions: {name: 'foo'})).to eq(foo)
  end

  it 'can not find nodes that does not exists' do
    expect(clazz.find(conditions: {name: 'unkown'})).to be_nil
  end

end


describe 'Neo4j::ActiveNode#all' do
  def create_clazz
    UniqueClass.create do
      include Neo4j::ActiveNode
      property :name
      property :score, type: Integer
      has_one :knows
    end
  end


  before(:all) do
    @clazz_a = create_clazz
    @clazz_b = create_clazz

    @b2 = @clazz_b.create(name: 'b2', score: '2')
    @b1 = @clazz_b.create(name: 'b1', score: '1')

    @a2 = @clazz_a.create(name: 'a2', score: '2', knows: @b2)
    @a1 = @clazz_a.create(name: 'a1', score: '1', knows: @b1)
    @a4 = @clazz_a.create(name: 'a4', score: '4', knows: @b1)
    @a3 = @clazz_a.create(name: 'a3', score: '3', knows: @b2)
  end

  it 'can find nodes that exists' do
    expect(@clazz_a.all(conditions: {score: 1}).to_a).to match_array([@a1])
  end

  it 'can sort them' do
    expect(@clazz_a.all(order: :score).to_a).to eq([@a1, @a2, @a3, @a4])
  end

  it 'can skip and limit result' do
    expect(@clazz_a.all(order: :score, skip: 1,limit: 2).to_a).to eq([@a2, @a3])
  end

  it 'can find all nodes having a relationship to another node' do
    expect(@clazz_a.all(conditions: {knows: @b2}).to_a).to match_array([@a3, @a2])
  end

  it 'can not find all nodes having a relationship to another node if there are non' do
    expect(@clazz_b.all(conditions: {knows: @a1}).to_a).to eq([])
  end

end