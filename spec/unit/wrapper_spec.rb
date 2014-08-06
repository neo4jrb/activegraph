require 'spec_helper'

describe Neo4j::Node::Wrapper do
  let(:wrapper) do
    obj = Object.new
    obj.extend(Neo4j::Node::Wrapper)
  end


  describe 'load_class_from_label' do
    it 'find classes' do
      clazz = UniqueClass.create
      wrapper.load_class_from_label(clazz.to_s).should == clazz
    end

    it 'returns nil if there is no class' do
      wrapper.load_class_from_label("some_unknown_class").should be_nil
    end

    it 'will auto load' do
      module AutoLoadTest
      end
      path = File.join(File.dirname(__FILE__), 'auto_load_test_a')
      AutoLoadTest.autoload(:MyClass, path)
      wrapper.load_class_from_label("AutoLoadTest::MyClass").should eq(AutoLoadTest::MyClass)
    end
  end

  describe 'check_label' do
    it 'will only check once' do
      expect(wrapper).to receive('load_class_from_label').with('some_label').once
      wrapper.check_label('some_label')
      wrapper.check_label('some_label')
    end

    it ' will check once per label' do
      expect(wrapper).to receive('load_class_from_label').with('some_label_a').once
      expect(wrapper).to receive('load_class_from_label').with('some_label_b').once
      wrapper.check_label('some_label_a')
      wrapper.check_label('some_label_b')
    end
  end

  describe 'wrapper' do
    describe "with class_name_property" do
      context 'when set in config.yml' do
        it 'looks for a property with the same name' do
          wrapper.stub(:props).and_return({_defined_property_name: 'Bar' })
          Bar = Object
          Neo4j::Config.stub(:class_name_property).and_return(:_defined_property_name)
          expect(wrapper.props).to receive(:has_key?).with(:_defined_property_name).and_return true

          expect(wrapper.sorted_wrapper_classes).to eq Bar
        end
      end

      context 'when using default and present on class' do
        before { wrapper.stub(:props).and_return({ _classname: 'CachedClassName'}) }
        CachedClassName = Object

        it 'does not call :_class_wrappers' do
          expect(wrapper).to_not receive(:_class_wrappers)
          wrapper.sorted_wrapper_classes
        end

        it 'looks for a key called "_classname"' do
          expect(wrapper.props).to receive(:has_key?).with(:_classname).and_return true
          wrapper.sorted_wrapper_classes
        end

        it 'returns the constantized value of "_classname"' do
          expect(wrapper.sorted_wrapper_classes).to eq CachedClassName
        end
      end

      context "when using default and missing on class" do
        it 'calls :_class_wrappers' do
          expect(wrapper).to receive(:_class_wrappers).once
          wrapper.stub(:props).and_return({})
          wrapper.sorted_wrapper_classes
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

    it "finds the most specific subclass and creates an instance for it"do
      class MyWrapper
        include Neo4j::Node::Wrapper
        def props
          42
        end
      end
      class B
      end

      class A < B
      end

      class D < A
      end

      class C < D
      end
      # make sure it picks the most specific class which is C in the following inheritance chain: C - D - A - B
      wrapper = MyWrapper.new

      label_mapping = {b: B, a: A, d: D, c: C}

      allow(Neo4j::ActiveNode::Labels).to receive(:_wrapped_labels).and_return(label_mapping)

      wrapper.should_receive(:_class_wrappers).and_return(label_mapping.keys)
      D.any_instance.should_receive(:init_on_load).with(wrapper, 42)
      wrapper.wrapper
    end
  end
end
