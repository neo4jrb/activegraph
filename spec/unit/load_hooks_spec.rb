describe 'load hooks' do
  require 'active_support'

  module HookedIn
    def hooked_in; end
  end

  [:active_node, :active_rel].each do |mod|
    ActiveSupport.on_load(mod) do
      include HookedIn
    end
  end

  it 'fires callbacks for ActiveGraph::ActiveNode' do
    class ANLoadTest; end
    expect(ANLoadTest.new).not_to respond_to(:hooked_in)

    class ANLoadTest
      include ActiveGraph::ActiveNode
    end

    expect(ANLoadTest.new).to respond_to(:hooked_in)
  end

  it 'fires callbacks for ActiveGraph::ActiveRel' do
    class ARLoadTest; end
    expect(ARLoadTest.new).not_to respond_to(:hooked_in)

    class ARLoadTest
      include ActiveGraph::ActiveRel
    end

    expect(ARLoadTest.new).to respond_to(:hooked_in)
  end
end
