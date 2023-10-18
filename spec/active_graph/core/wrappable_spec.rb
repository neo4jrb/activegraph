describe ActiveGraph::Core::Wrappable do
  before do
    stub_const 'WrapperClass', (Class.new do
      attr_reader :wrapped_object

      def initialize(obj)
        @wrapped_object = obj
      end
    end)

    stub_const 'WrappableClass', (Class.new do
      include ActiveGraph::Core::Wrappable
    end)
  end

  describe '.wrapper_callback' do
    it 'does not allow for two callbacks' do
      WrappableClass.wrapper_callback(&WrapperClass.method(:new))

      expect do
        WrappableClass.wrapper_callback {}
      end.to raise_error(/Callback already specified!/)
    end

    it 'returns the wrappable object if no callback is specified' do
      obj = WrappableClass.new
      expect(obj.wrap).to eq(obj)
    end

    it 'allow users to specify a callback which will create a wrapper object' do
      WrappableClass.wrapper_callback(&WrapperClass.method(:new))

      obj = WrappableClass.new
      wrapper_obj = obj.wrap
      expect(wrapper_obj.wrapped_object).to eq(obj)
    end
  end

  # Should pass on method calls?
end
