require 'spec_helper'

describe Neo4j::Node::Wrapper do
  it "finds the most specific subclass and creates an instance for it" do
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
#    Neo4j::ActiveNode::Labels._wrapped_labels.should_receive(:[]).with(X3).and_return(X3)
    wrapper.should_receive(:_class_wrappers).and_return(label_mapping.keys)
    D.any_instance.should_receive(:init_on_load).with(wrapper, 42)
    wrapper.wrapper
  end
end
