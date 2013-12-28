require 'spec_helper'

describe 'simple things', type: :e2e do
  it 'can do' do
    class FooPerson
      include Neo4j::ActiveNode
      property :name
      index :name
    end

    f = FooPerson.new(name: 'andreas')
    #f.name = 'hej'
    puts f[:name]
    f.save
    puts "F #{f.name}, labels #{f.labels.inspect}"
    puts f[:name]

    puts
  end
end