require 'spec_helper'

describe 'Module handling from config: :module_handling option' do
  let(:clazz) do
    Class.new do
      include Neo4j::ActiveNode
    end
  end

  before { stub_const 'ModuleTest::Student', clazz }
  after do
    Neo4j::Config[:association_model_namespace] = nil
    Neo4j::Config[:module_handling] = nil
  end

  describe 'labels' do
    context 'with config unspecified or neither :demodulize nor a proc' do
      it 'are set using the full module and class name' do
        expect(ModuleTest::Student.mapped_label_name).to eq :'ModuleTest::Student'
      end
    end

    context 'with config set to :demodulize' do
      before { Neo4j::Config[:module_handling] = :demodulize }

      it 'strips module names from labels' do
        expect(ModuleTest::Student.mapped_label_name).to eq :Student
        node = ModuleTest::Student.create
        expect(ModuleTest::Student.first.neo_id).to eq node.neo_id
      end
    end

    context 'with a proc' do
      before do
        Neo4j::Config[:module_handling] = proc do |name|
          module_name = name.deconstantize
          name.gsub(module_name, 'Foo')
        end
      end

      it 'lets you modify the name as you see fit' do
        expect(ModuleTest::Student.mapped_label_name).to eq :'Foo::Student'
      end
    end
  end

  describe 'association model locations' do
    let(:discovered_model) { clazz.associations[:students].instance_variable_get(:@target_class_option) }

    context 'with config set to :none or unspecified' do
      before { clazz.has_many :out, :students }

      it 'expects a class with the singular version of the association' do
        expect(discovered_model).to eq '::Student'
      end
    end

    context ' with :association_model_namespace set' do
      before do
        Neo4j::Config[:association_model_namespace] = 'ModuleTest'
        clazz.has_many :out, :students
      end

      it 'expects namespacing and looks for a model in the same namespace as the source' do
        expect(discovered_model).to eq '::ModuleTest::Student'
        node1 = ModuleTest::Student.create
        node2 = ModuleTest::Student.create
        node1.students << node2
        expect(node1.students.to_a).to include node2
      end
    end
  end

  describe 'node wrapping' do
    before do
      Neo4j::Config[:module_handling] = :demodulize
      Neo4j::ActiveNode::Labels::MODELS_FOR_LABELS_CACHE.clear
    end
    let(:cache) { Neo4j::ActiveNode::Labels::MODELS_FOR_LABELS_CACHE }

    it 'saves the map of label to class correctly when labels do not match class' do
      expect(cache).to be_empty
      ModuleTest::Student.create
      ModuleTest::Student.first
      expect(cache).not_to be_empty
      expect(cache[[:Student]]).to eq ModuleTest::Student
    end
  end
end
