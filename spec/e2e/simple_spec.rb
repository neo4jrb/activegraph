require 'spec_helper'

describe 'simple things', type: :e2e do
  it 'can do' do
    class FooPerson
      include Neo4j::ActiveNode
      property :name
    end

    f = FooPerson.new(name: 'hej hop')
    #f.name = 'hej'
    puts f[:name]
    puts "F #{f.name}"
    f.save
    puts f[:name]

    puts
  end
end