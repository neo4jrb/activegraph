require 'spec_helper'

describe Neo4j::Node::Wrapper do
  it "finds the most specific subclass and creates an instance for it" do
    class MyWrapper
      include Neo4j::Node::Wrapper
      def props
        42
      end
    end
    class X1

    end

    class X2 < X1

    end

    class X3 < X2

    end

    wrapper = MyWrapper.new
    Neo4j::ActiveNode::Labels._wrapped_labels.should_receive(:[]).with(X3).and_return(X3)
    wrapper.should_receive(:_class_wrappers).and_return([X3,X1,X2])
    X3.any_instance.should_receive(:init_on_load).with(wrapper, 42)
    wrapper.wrapper
  end
end
