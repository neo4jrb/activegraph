require 'spec_helper'

describe 'wrapped nodes in transactions' do
  module TransactionNode
    class Student
      include Neo4j::ActiveNode
      property :name
    end
  end

  let!(:clazz) { TransactionNode::Student }
  before do
    clazz.create(name: 'John')
    tx = Neo4j::Transaction.new
    @student = clazz.first
    tx.close
  end
  after { clazz.destroy_all }

  it 'can load a node within a transaction' do 
    expect(@student).to be_a(clazz)
    expect(@student.name).to eq 'John'
    expect(@student.id).not_to be_nil
  end

  # here's where the problems start
  it 'returns its :labels' do
    expect(@student.neo_id).to be_nil
    expect(@student.labels).to eq [clazz.to_sym]
  end

  it 'responds positively to exist?' do
    expect(@student.exist?).to be_truthy
  end

  # and so on
end
