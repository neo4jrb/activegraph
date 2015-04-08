require 'spec_helper'

describe Neo4j::Node::Wrapper do
  let(:wrapper) do
    obj = Object.new
    obj.extend(Neo4j::Node::Wrapper)
  end

  describe 'wrapper' do
    describe 'with class_name_property' do
      context 'when set in config.yml' do
        it 'looks for a property with the same name' do
          wrapper.stub(:props).and_return(_defined_property_name: 'Bar')
          wrapper.stub(:labels).and_return([])
          Bar = Object
          Neo4j::Config.stub(:class_name_property).and_return(:_defined_property_name)

          expect(wrapper.class_to_wrap).to eq Bar
        end
      end

      context 'when using default and present on class' do
        before do
          wrapper.stub(:props).and_return(_classname: 'CachedClassName')
          wrapper.stub(:labels).and_return([])
        end

        CachedClassName = Object

        it 'does not call :_class_wrappers' do
          expect(wrapper).to_not receive(:_class_wrappers)
          wrapper.class_to_wrap
        end

        it 'looks for a key called "_classname"' do
          expect(wrapper.props).to receive(:key?).with(:_classname).and_return true
          wrapper.class_to_wrap
        end

        it 'returns the constantized value of "_classname"' do
          expect(wrapper.class_to_wrap).to eq CachedClassName
        end
      end
    end

    it 'can find the wrapper even if it is auto loaded' do
      module AutoLoadTest
      end
      path = File.join(File.dirname(__FILE__), 'auto_load_test_b')
      AutoLoadTest.autoload(:MyWrapperClass, path)
      allow(wrapper).to receive(:props).and_return({})
      allow(wrapper).to receive(:labels).and_return([:'AutoLoadTest::MyWrapperClass'])
      obj = wrapper.wrapper
      obj.should be_kind_of(AutoLoadTest::MyWrapperClass)
    end
  end
end
