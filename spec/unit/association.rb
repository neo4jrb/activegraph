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

    context 'direction = :invalid' do
      let(:direction) { :invalid }

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

  end
end
