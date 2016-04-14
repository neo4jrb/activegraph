describe Neo4j::Node::Wrapper do
  let(:wrapper) do
    obj = Object.new
    obj.extend(Neo4j::Node::Wrapper)
  end

  describe 'wrapper' do
    it 'can find the wrapper even if it is auto loaded' do
      module AutoLoadTest
      end
      path = File.join(File.dirname(__FILE__), 'auto_load_test_b')
      AutoLoadTest.autoload(:MyWrapperClass, path)
      allow(wrapper).to receive(:props).and_return({})
      allow(wrapper).to receive(:labels).and_return([:'AutoLoadTest::MyWrapperClass'])
      obj = wrapper.wrapper
      expect(obj).to be_kind_of(AutoLoadTest::MyWrapperClass)
    end
  end
end
