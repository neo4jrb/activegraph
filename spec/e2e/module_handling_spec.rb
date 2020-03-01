describe 'Module handling from config: :module_handling option' do
  before do
    clear_model_memory_caches

    stub_node_class('Clazz')
  end

  before do
    stub_named_class 'ModuleTest::Student', Clazz
    ActiveGraph::Config[:association_model_namespace] = nil
    ActiveGraph::Config[:module_handling] = nil
  end

  describe 'labels' do
    context 'with config unspecified or neither :demodulize nor a proc' do
      it 'are set using the full module and class name' do
        expect(ModuleTest::Student.mapped_label_name).to eq :'ModuleTest::Student'
        expect(ModuleTest::Student.send(:decorated_label_name)).to eq :'ModuleTest::Student'
      end
    end

    context 'with config set to :demodulize' do
      before { ActiveGraph::Config[:module_handling] = :demodulize }

      it 'strips module names from labels' do
        expect(ModuleTest::Student.mapped_label_name).to eq :Student
        expect(ModuleTest::Student.send(:decorated_label_name)).to eq :Student
        node = ModuleTest::Student.create
        expect(ModuleTest::Student.first.neo_id).to eq node.neo_id
      end
    end

    context 'with a proc' do
      before do
        ActiveGraph::Config[:module_handling] = proc do |name|
          module_name = name.deconstantize
          name.gsub(module_name, 'Foo')
        end
      end

      it 'lets you modify the name as you see fit' do
        expect(ModuleTest::Student.mapped_label_name).to eq :'Foo::Student'
        expect(ModuleTest::Student.send(:decorated_label_name)).to eq :'Foo::Student'
      end
    end
  end

  describe 'association model locations' do
    let(:discovered_target_class_names) { Clazz.associations[:students].target_class_names }

    context 'with config set to :none or unspecified' do
      before { Clazz.has_many :out, :students, type: :HAS_STUDENT }

      it 'expects a class with the singular version of the association' do
        expect(discovered_target_class_names).to eq ['::Student']
      end
    end

    context ' with :association_model_namespace set' do
      before do
        ActiveGraph::Config[:association_model_namespace] = 'ModuleTest'
        Clazz.has_many :out, :students, type: :HAS_STUDENT
      end

      it 'expects namespacing and looks for a model in the same namespace as the source' do
        expect(discovered_target_class_names).to eq ['::ModuleTest::Student']
        node1 = ModuleTest::Student.create
        node2 = ModuleTest::Student.create
        node1.students << node2
        expect(node1.students.to_a).to include node2
      end
    end
  end

  describe 'node wrapping' do
    before do
      ActiveGraph::Config[:module_handling] = :demodulize
    end
    let!(:cache) { ActiveGraph::Node::Labels::MODELS_FOR_LABELS_CACHE }

    it 'saves the map of label to class correctly when labels do not match class' do
      expect(cache).to be_empty
      ModuleTest::Student.create
      ModuleTest::Student.first
      expect(cache).not_to be_empty
      expect(cache[[:Clazz, :Student]]).to eq ModuleTest::Student
    end
  end

  describe 'Relationship' do
    let(:test_config) do
      proc do |config_option|
        ActiveGraph::Config[:module_handling] = config_option
        # Relationship types are misbehaving when using stub_const, will have to fix later
        module ModuleTest
          class RelClass
            include ActiveGraph::Relationship
          end
        end
      end
    end

    context 'with module_handling set to demodulize' do
      before { test_config.call(:demodulize) }

      it 'respects the option when setting rel type' do
        expect(ModuleTest::RelClass._type).to eq 'REL_CLASS'
        expect(ModuleTest::RelClass.namespaced_model_name).to eq 'RelClass'
      end
    end

    context 'with module_handling set to none or not set' do
      before { test_config.call(:none) }

      it 'uses the full Module::Class name' do
        expect(ModuleTest::RelClass._type).to eq 'MODULE_TEST::REL_CLASS'
        expect(ModuleTest::RelClass.namespaced_model_name).to eq 'ModuleTest::RelClass'
      end
    end

    context 'with module_handling set to a proc' do
      before do
        custom_config = proc { |name| name.gsub('::', '_FOO_') }
        test_config.call(custom_config)
      end

      it 'modifies the type as expected' do
        expect(ModuleTest::RelClass._type).to eq 'MODULE_TEST_FOO_REL_CLASS'
        expect(ModuleTest::RelClass.namespaced_model_name).to eq 'ModuleTest_FOO_RelClass'
      end
    end
  end
end
