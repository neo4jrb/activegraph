describe 'load hooks' do
  module HookedIn
    def hooked_in; end
  end

  [:node, :relationship].each do |mod|
    ActiveSupport.on_load(mod) do
      include HookedIn
    end
  end

  it 'fires callbacks for ActiveGraph::Node' do
    class ANLoadTest; end
    expect(ANLoadTest.new).not_to respond_to(:hooked_in)

    class ANLoadTest
      include ActiveGraph::Node
    end

    expect(ANLoadTest.new).to respond_to(:hooked_in)
  end

  it 'fires callbacks for ActiveGraph::Relationship' do
    class ARLoadTest; end
    expect(ARLoadTest.new).not_to respond_to(:hooked_in)

    class ARLoadTest
      include ActiveGraph::Relationship
    end

    expect(ARLoadTest.new).to respond_to(:hooked_in)
  end
end
