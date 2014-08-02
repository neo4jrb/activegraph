require 'spec_helper'

class Default
end

describe Neo4j::ActiveNode::HasN::Association do
  let(:options) { {} }
  let(:name) { :default }
  let(:direction) { :out }

  let(:association) { Neo4j::ActiveNode::HasN::Association.new(type, direction, name, options) }
  subject { association }

  context 'type = :invalid' do
    let(:type) { :invalid }

    it { expect { subject }.to raise_error(ArgumentError) }
  end

  context 'has_many' do
    let(:type) { :has_many }

    ### Validations

    context 'direction = :invalid' do
      let(:direction) { :invalid }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'origin and type specified' do
      let(:options) { {type: :bar, origin: :foo} }

      it { expect { subject }.to raise_error(ArgumentError) }
    end



    describe '#arrow_cypher' do
      let(:var) { nil }
      let(:properties) { {} }
      let(:create) { false }

      subject { association.arrow_cypher(var, properties, create) }

      it { should == '-[]->' }

      context 'inbound' do
        let(:direction) { :in }

        it { should == '<-[]-' }
      end

      context 'bidirectional' do
        let(:direction) { :both }

        it { should == '-[]-' }
      end

      context 'creation' do
        let(:create) { true }

        it { should == '-[:`#default`]->' }

        context 'properties given' do
          let(:properties) { {foo: 1, bar: 'test'} }

          it { should == '-[:`#default` {foo: 1, bar: "test"}]->' }
        end
      end

      context 'varable given' do
        let(:var) { :fooy }

        it { should == '-[fooy]->' }

        context 'properties given' do
          let(:properties) { {foo: 1, bar: 'test'} }

          it { should == '-[fooy {foo: 1, bar: "test"}]->' }
        end

        context 'creation' do
          let(:create) { true }

          it { should == '-[fooy:`#default`]->' }

          context 'properties given' do
            let(:properties) { {foo: 1, bar: 'test'} }

            it { should == '-[fooy:`#default` {foo: 1, bar: "test"}]->' }
          end

        end
      end

    end

    describe "#target_class_name" do
      subject { association.target_class_name }

      context "assumed model class" do
        let(:name) { :burzs }

        it { should == 'Burz' }
      end


      context "specified model class" do
        context "specified as string" do
          let(:options) { {model_class: 'Bizzl'} }

          it { should == 'Bizzl' }
        end

        context "specified as class" do
          before(:each) do
            stub_const 'Fizzl', Class.new { include Neo4j::ActiveNode }
          end

          let(:options) { {model_class: 'Fizzl'} }

          it { should == 'Fizzl' }
        end
      end

    end

  end


end
