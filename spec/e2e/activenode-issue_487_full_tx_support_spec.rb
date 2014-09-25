require 'spec_helper'

describe 'wrapped nodes in transactions', api: :server do
  module TransactionNode
    class Student
      include Neo4j::ActiveNode
      id_property :id, auto: :uuid

      property :name
    end
  end

  before(:all) do
    @clazz = TransactionNode::Student
    @clazz.create(name: 'John')
    begin
      tx = Neo4j::Transaction.new
      @student = @clazz.first
    ensure
      tx.close
    end
  end

  after(:all) { @clazz.destroy_all }

  it 'can load a node within a transaction' do
    expect(@student).to be_a(@clazz)
    expect(@student.name).to eq 'John'
    expect(@student.id).not_to be_nil
  end

  it 'returns the activenode object as the delegator' do
    expect(@student._persisted_obj.delegator).to eq @student
  end

  # here's where the problems start
  it 'returns its :labels' do
    expect(@student.neo_id).not_to be_nil
    expect(@student.labels).to eq [@clazz.name.to_sym]
  end

  it 'responds positively to exist?' do
    expect(@student.exist?).to be_truthy
  end

  # and so on
end
