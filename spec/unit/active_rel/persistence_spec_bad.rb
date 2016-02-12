require 'spec_helper'

describe Neo4j::ActiveRel::Persistence do
  let(:session) { double('Session') }
  let(:node1) { double('first persisted node') }
  let(:node2) { double('second persisted node') }
  let(:rel)   { double('a persisted rel') }

  before do
    allow(node1).to receive(:neo_id).and_return(1)
    allow(node2).to receive(:neo_id).and_return(2)
    @session = double('Mock Session')
    allow(Neo4j::Session).to receive(:current).and_return(@session)
    allow(clazz).to receive(:neo4j_session).and_return(session)
  end

  let(:clazz) do
    Class.new do
      include Neo4j::ActiveRel::Initialize
      include Neo4j::ActiveRel::Persistence
      include Neo4j::ActiveRel::Property

      from_class Class
      to_class Class

      type :friends_with

      property :friends_since
      property :level, type: Integer
    end
  end

  describe 'initialize' do
    it 'can take a hash of properties' do
      r = clazz.new(friends_since: 'sunday', level: 9001)
      expect(r.props).to eq(friends_since: 'sunday', level: 9001)
    end

    it 'raises an error when given a property which is not defined' do
      expect { clazz.new(unknown: true) }.to raise_error(Neo4j::Shared::Property::UndefinedPropertyError)
    end
  end

  describe 'save' do
    it 'creates a relationship if not already persisted' do
      start_props = {from_node: node1, to_node: node2, friends_since: 'sunday', level: 9001}
      end_props   = {friends_since: 'sunday', level: 9001}
      r = clazz.new(start_props)
      allow(r).to receive(:confirm_node_classes).and_return(:true)
      expect(node1).to receive(:create_rel).with(:friends_with, node2, friends_since: 'sunday', level: 9001).and_return(rel)
      allow(rel).to receive(:props).and_return(end_props)
      expect(r.save).to be_truthy
    end

    it 'does not update the rel if nothing changes' do
      r = clazz.new(to_node: node1, from_node: node2, friends_since: 'sunday', level: 9001)
      allow(r).to receive(:_persisted_obj).and_return(rel)
      allow(r).to receive(:changed_attributes).and_return({})
      expect(rel).to receive(:exist?).and_return(true)
      r.save
    end

    it 'commits changes to an existing relationship' do
      r = clazz.new(to_node: node1, from_node: node2, friends_since: 'forever')
      allow(r).to receive(:_persisted_obj).and_return(rel)
      expect(rel).to receive(:exist?).and_return(true)
      expect(rel).to receive(:update_props).and_return(friends_since: 'forever')
      expect(r.save).to be_truthy
    end

    describe 'confirming model types' do
      before(:all) do
        class ThisClass; end
        class ThatClass; end
      end
      let(:this_class_node) { ThisClass.new }
      let(:that_class_node) { ThatClass.new }

      context 'with unexpected types' do
        before do
          clazz.from_class ThatClass
          clazz.to_class ThisClass
        end

        let(:r) { clazz.new(from_node: this_class_node, to_node: that_class_node) }

        it 'raises an error' do
          expect(that_class_node).not_to receive(:create_rel)
          expect { r.save }.to raise_error(Neo4j::ActiveRel::Persistence::ModelClassInvalidError)
        end
      end

      context 'with expected types' do
        before do
          clazz.from_class ThisClass
          clazz.to_class ThatClass
        end

        let(:r) { clazz.new(from_node: this_class_node, to_node: that_class_node, friends_since: 2002) }

        def model_stubs
          expect(this_class_node).to receive(:class).at_least(1).times.and_return(ThisClass)
          allow_any_instance_of(clazz).to receive(:_create_rel)
          allow_any_instance_of(clazz).to receive(:init_on_load)
        end

        def model_expectations
          expect { r.save }.not_to raise_error
          r.friends_since = 2014
          expect { r.save }.not_to raise_error
        end

        it 'does not raise an error' do
          model_stubs
          model_expectations
        end

        it 'converts symbols to constants' do
          clazz.from_class :ThisClass
          model_stubs
          model_expectations
        end

        context 'with string types' do
          before do
            clazz.from_class 'ThisClass'
            clazz.to_class 'ThatClass'
          end

          it 'does not raise an error' do
            model_stubs
            model_expectations
          end

          it 'raises an error if a string class is given that does not exist' do
            clazz.from_class 'ThizFoo'
            allow_any_instance_of(clazz).to receive(:_create_rel)
            allow_any_instance_of(clazz).to receive(:init_on_load)
            expect { r.save }.to raise_error NameError
          end
        end

        context 'with :any or false types' do
          before do
            clazz.from_class :any
            clazz.to_class :any
          end

          def any_stubs
            expect(this_class_node).not_to receive(:class)
            expect(that_class_node).not_to receive(:class)
            allow_any_instance_of(clazz).to receive(:_create_rel)
            allow_any_instance_of(clazz).to receive(:init_on_load)
          end

          it 'does not check the classes of the nodes' do
            any_stubs
            expect { r.save }.not_to raise_error
          end

          it 'accepts false instead of :any' do
            clazz.from_class false
            clazz.to_class false
            any_stubs
            expect { r.save }.not_to raise_error
          end
        end
      end
    end
  end

  describe 'save!' do
    it 'raises an exception if invalid' do
      allow_any_instance_of(clazz).to receive(:save).and_return(false)
      allow_any_instance_of(clazz).to receive_message_chain('errors.full_messages').and_return([])
      expect do
        clazz.new.save!
      end.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end
  end

  describe 'create' do
    it 'creates a new relationship' do
      expect(clazz).to receive(:extract_association_attributes!).twice.and_return(from_node: node1, to_node: node2)
      allow_any_instance_of(clazz).to receive(:confirm_node_classes).and_return(:true)
      allow(node1).to receive(:create_rel).and_return(rel)
      allow(rel).to receive(:props).and_return(friends_since: 'yesterday', level: 5)
      expect(clazz.create(from_node: node1, to_node: node2, friends_since: 'yesterday', level: 5)).to be_truthy
    end
  end

  describe 'create!' do
    it 'raises an exception if invalid' do
      allow(clazz).to receive(:create).and_return(false)
      allow(clazz).to receive_message_chain('errors.full_messages').and_return([])
      expect do
        clazz.create!
      end.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end
  end
end
